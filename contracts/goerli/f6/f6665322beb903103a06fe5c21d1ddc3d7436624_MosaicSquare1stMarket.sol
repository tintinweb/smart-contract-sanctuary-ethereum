/*

                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀

*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./1stMarket/MarketCore.sol";
import "./1stMarket/Auction.sol";
import "./1stMarket/FixedPrice.sol";

import "./Utils/AdminTreasury.sol";
import "./Utils/Constants.sol";
import "./Utils/SendValueWithFallbackWithdraw.sol";

/***************************************************************************************************
* @title A 1st market for MosaicSquare.
* @notice Notice 테스트 한글 123
* @dev 주석 주석 Code size is 26679 bytes
****************************************************************************************************/
contract MosaicSquare1stMarket is Constants, Initializable, AdminTreasury, MarketCore, SendValueWithFallbackWithdraw, MarketAuction, MarketFixedPrice {
/***************************************************************************************************
* @title Set initialization when creating contracts
****************************************************************************************************/
  constructor() {}

/***************************************************************************************************
* @notice Called once to configure the contract after the initial proxy deployment.
* @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
****************************************************************************************************/
  function initialize(address _contractAdmin, address payable _treasury) external initializer {
    _initializeAdminTreasury(_contractAdmin, _treasury);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev This is a no-op function required to avoid compile errors.
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal override(MarketCore, MarketAuction, MarketFixedPrice) {
    super._checkRegisteredMarket(nftContract, tokenId); 
  }

/***************************************************************************************************
* @notice Withdrawal to all those who will be withdrawn
****************************************************************************************************/
  function withdrawAll() external {
    _withdrawAll(SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
  }

/***************************************************************************************************
* @notice NFT Return
* @param nftContract address of the NFT contract
* @param tokenId NFT token id
* @param seller address of the seller
****************************************************************************************************/
  function returnNFT(address nftContract, uint256 tokenId, address seller) external onlyAdmin {
    _checkRegisteredMarket(nftContract, tokenId); // Check if it is registered in the market
    _transferFromMarket(nftContract, tokenId, seller);
  }
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../Utils/Constants.sol";

/***************************************************************************************************
* @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
* @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
****************************************************************************************************/
abstract contract MarketCore is Constants, Initializable {
  using AddressUpgradeable for address;

  uint256 private minIncrement;
  uint16 public marketFee;

  mapping (uint256 => bool) private durationSettingPeriod;

/***************************************************************************************************
* @notice initialization
****************************************************************************************************/  
  function _initializeMarketCore() internal onlyInitializing {
    minIncrement = MIN_INCREMENT_OFFER;
    marketFee = DEFAULT_MARKET_FEE_POINTS;
    durationSettingPeriod[1 days] = true;
    durationSettingPeriod[3 days] = true;
    durationSettingPeriod[7 days] = true;
  }

/***************************************************************************************************
* @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenId);
  }

/***************************************************************************************************
* @notice Transfers an NFT into escrow,
* if already there this requires the msg.sender is authorized to manage the sale of this NFT.
****************************************************************************************************/
  function _transferToMarket(address nftContract, uint256 tokenId) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

/***************************************************************************************************
* @dev Determines the minimum amount when increasing an existing offer or bid.
****************************************************************************************************/
  function _getMinIncrement(uint256 currentAmount) internal view returns (uint256) {
    return minIncrement + currentAmount;
  }

/***************************************************************************************************
* @notice Set minimal increase value
****************************************************************************************************/
  function _updateMinIncrement(uint256 _minIncrement) internal {
    minIncrement = _minIncrement;
  }

/***************************************************************************************************
* @notice Market fee setting
****************************************************************************************************/
  function _updateMarketFee(uint16 _marketFee) internal {
    if (MIN_MARKET_FEE_POINTS > _marketFee || _marketFee > MAX_MARKET_FEE_POINTS) {
      revert("MarketCore: Market fee value error");
    }
    marketFee = _marketFee;
  }

/***************************************************************************************************
* @notice Duration setting period update
****************************************************************************************************/
  function _addDurationSettingPeriod(uint256 _period) internal {
    durationSettingPeriod[_period] = true;
  }

/***************************************************************************************************
* @notice Duration setting period remove
****************************************************************************************************/
  function _removeDurationSettingPeriod(uint256 _period) internal {
    delete durationSettingPeriod[_period];
  }

/***************************************************************************************************
* @notice Check duration setting period
****************************************************************************************************/
  function _checkDurationSettingPeriod(uint256 _period) internal view returns (bool) {
    return durationSettingPeriod[_period];
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
* @dev 50 slots were consumed by adding `ReentrancyGuard`.
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../Utils/Constants.sol";

/***************************************************************************************************
* @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
* @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
****************************************************************************************************/
abstract contract MarketCore is Constants {
  using AddressUpgradeable for address;

/***************************************************************************************************
* @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenId);
  }

/***************************************************************************************************
* @notice Check that the NFT is registered in the market
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal virtual {}

/***************************************************************************************************
* @dev Determines the minimum amount when increasing an existing offer or bid.
****************************************************************************************************/
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = 0;
    if (currentAmount < 1 ether) {
      minIncrement = currentAmount * MIN_PERCENT_INCREMENT_IN_POINTS;
    } else {
      minIncrement = currentAmount * MAX_PERCENT_INCREMENT_IN_POINTS;
    }
    unchecked {
      minIncrement /= BASIS_POINTS;
      if (minIncrement == 0) {
        // Since minIncrement reduces from the currentAmount, this cannot overflow.
        // The next amount must be at least 1 wei greater than the current.
        return currentAmount + 1;
      }
    }

    return minIncrement + currentAmount;
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./MarketCore.sol";
import "./MarketFees.sol";
//import "./ErrorMessage.sol";

import "../Utils/AdminTreasury.sol";
import "../Utils/Constants.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";
import "../Utils/SupportsInterfaces.sol";

/***************************************************************************************************
* @title A market for MosaicSquare.
* @notice Notice 테스트 한글 123
* @dev 주석 주석
****************************************************************************************************/
abstract contract MarketAuction is Constants, AdminTreasury, MarketCore, ReentrancyGuardUpgradeable, SupportsInterfaces, SendValueWithFallbackWithdraw, MarketFees {
  using AddressUpgradeable for address payable;
  using StringsUpgradeable for uint256;
/***************************************************************************************************
* @notice Stores the auction configuration for a specific NFT.
****************************************************************************************************/
  struct AuctionData {
    address payable seller; // The owner of the NFT which listed it in auction.
    uint256 startTime;      // Save the auction time in the form of Unix Timestamp.
    uint256 duration;       // Auction period setting value after the first beading
    uint256 endTime;        // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
    uint16 marketFee;       // Market fee
    address payable bidder; // The current highest bidder in this auction. This is `address(0)` until the first bid is placed.
    uint256 amount;         // The latest price of the NFT in this auction. This is set to the reserve price, and then to the highest bid once the auction has started.
  }

  mapping(address => mapping(uint256 => AuctionData)) private nftContractTokenIdToAuctionData; // The auction configuration for a specific auction id.

/***************************************************************************************************
* @notice Emitted when a bid is placed.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param bidder The address of the bidder.
* @param amount The amount of the bid.
* @param originalBidder The address of the original bidder.
* @param originalAmount The amount of the original bid.
* @param endTime The new end time of the auction (which may have been set or extended by this bid).
****************************************************************************************************/
  event AuctionBidPlaced(address indexed nftContract, uint256 indexed tokenId, address bidder, uint256 amount, address originalBidder, uint256 originalAmount, uint256 endTime);
/***************************************************************************************************
* @notice Emitted when an auction is cancelled.
* @dev This is only possible if the auction has not received any bids.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param reason The reason for the cancellation.
****************************************************************************************************/
  event AuctionCanceled(address indexed nftContract, uint256 indexed tokenId, string reason);
/***************************************************************************************************
* @notice Emitted when an NFT is listed for auction.
* @param seller The address of the seller.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param duration The duration of the auction (always 24-hours).
* @param extensionDuration The duration of the auction extension window (always 15-minutes).
* @param reservePrice The reserve price to kick off the auction.
****************************************************************************************************/
  event AuctionCreated(address indexed nftContract, uint256 indexed tokenId, address seller, uint256 duration, uint256 extensionDuration, uint256 reservePrice);
/***************************************************************************************************
* @notice Emitted when an auction that has already ended is finalized, 
* indicating that the NFT has been transferred and revenue from the sale distributed.
* @dev The amount of the highest bid / final sale price for this auction is `mssFee` + `creatorFee` + `ownerRev`.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param seller The address of the seller.
* @param bidder The address of the highest bidder that won the NFT.
* @param value The value of the NFT.
* @param mssFee The amount of ETH that was sent to market for this sale.
* @param creatorFee The amount of ETH that was sent to the creator for this sale.
****************************************************************************************************/
  event AuctionFinalized(address indexed nftContract, uint256 indexed tokenId, address seller, address bidder, uint256 value, uint256 mssFee, uint256 creatorFee);
/***************************************************************************************************
* @notice Allows market to cancel an auction, refunding the bidder
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param reason The reason for the cancellation (a required field).
****************************************************************************************************/
  function adminCancelAuction(address nftContract, uint256 tokenId, string calldata reason) external onlyAdmin {
    require(bytes(reason).length != 0, "MarketAuction: Cannot admin cancel without reason");
    
    AuctionData memory auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    require(auction.seller != address(0), "MarketAuction: Cannot cancel nonexistent auction");
    delete nftContractTokenIdToAuctionData[nftContract][tokenId];

    if (auction.bidder != address(0)) {
      // Refund the highest bidder if any bids were placed in this auction.
      _sendValueWithFallbackWithdraw(nftContract, tokenId, auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionCanceled(nftContract, tokenId, reason);
  }

/***************************************************************************************************  
* @notice Creates an auction for the given NFT.
* @dev Before this operation, the NFT owner must be the market.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param auctionPrice The initial reserve price for the auction.
****************************************************************************************************/
  function createAuction(address nftContract, uint256 tokenId, address seller, uint256 auctionPrice, uint256 startUnixTime, uint256 duration, uint16 marketFee) external onlyAdmin {
    require(auctionPrice >= MIN_START_PRICE, 
      string(abi.encodePacked("MarketAuction: Price must be greater than ", MIN_START_PRICE.toString(), " wei")));
    require(duration >= EXTENSION_DURATION, 
      string(abi.encodePacked("MarketAuction: Duration must be at least ", EXTENSION_DURATION.toString(), " seconds")));
    if (MIN_MARKET_FEE_POINTS > marketFee || marketFee > MAX_MARKET_FEE_POINTS) {
      revert(string(abi.encodePacked("MarketAuction: The market fees are between ",
           uint256(MIN_MARKET_FEE_POINTS).toString(), " to ", uint256(MAX_MARKET_FEE_POINTS).toString())));
    }
    _checkRegisteredMarket(nftContract, tokenId);

    // 이 컨트랙트가 소유자인지 확인하고 소유자가 아니면 에러
    require(address(this) == _getInterfacesOwnerOf(nftContract, tokenId), "MarketAuction: Only NFT contract owner can create auction");

    // 로열티 정보가 없으면 에러
    (address checkRoyaltyInfo,) = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    require(checkRoyaltyInfo != address(0), "MarketAuction: Royalty info not found");

    // Store the auction details
    nftContractTokenIdToAuctionData[nftContract][tokenId] = AuctionData(
      payable(seller), startUnixTime, duration, 0, // endTime is only known once the reserve price is met
      marketFee, payable(0), // bidder is only known once a bid has been placed
      auctionPrice
    );

    emit AuctionCreated(nftContract, tokenId, seller, duration, EXTENSION_DURATION, auctionPrice);
  }

/***************************************************************************************************
* @notice Place a bid in an auction.
* A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
* If this is the first bid on the auction, the countdown will begin.
* If there is already an outstanding bid, the previous bidder will be refunded at this time
* and if the bid is placed in the final moments of the auction, the countdown may be extended.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function placeBid(address nftContract, uint256 tokenId) external payable {
    AuctionData storage auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    require(auction.startTime <= block.timestamp, "MarketAuction: Cannot bid on an auction that has not been started");
    require(auction.seller != address(0), "MarketAuction: Cannot bid on nonexistent auction");
    require(auction.seller != msg.sender, "MarketAuction: Cannot bid on your own auction");

    uint256 originalAmount = 0;
    address payable originalBidder = payable(0);

    if (auction.endTime == 0) {
      // This is the first bid, kicking off the auction.
      require(msg.value >= auction.amount, "MarketAuction: Cannot bid lower than reserve price");

      // Store the bid details.
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);

      unchecked {
        auction.endTime =  block.timestamp + auction.duration;
      }
    } else {
      require(block.timestamp <= auction.endTime, "MarketAuction: Cannot bid on ended auction");
      require(auction.bidder != msg.sender, "MarketAuction: Cannot rebid over outstanding bid");
      require(msg.value >= _getMinIncrement(auction.amount), "MarketAuction: Bid must be at least min amount");
        
      // Cache and update bidder state
      originalAmount = auction.amount;
      originalBidder = auction.bidder;
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);

      unchecked {
        // When a bid outbids another, check to see if a time extension should apply.
        // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
        if (auction.endTime - block.timestamp < EXTENSION_DURATION) {
          // Current time plus extension duration (always 10 mins) cannot overflow.
          auction.endTime = block.timestamp + EXTENSION_DURATION;
        }
      }
      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(nftContract, tokenId, originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionBidPlaced(nftContract, tokenId, msg.sender, msg.value, originalBidder, originalAmount, auction.endTime);
  }

/***************************************************************************************************
* @notice Once the countdown has expired for an auction, anyone can settle the auction.
* This will send the NFT to the highest bidder and distribute revenue for this sale.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function finalizeAuction(address nftContract, uint256 tokenId) external nonReentrant {
    require(nftContractTokenIdToAuctionData[nftContract][tokenId].endTime != 0, "MarketAuction: Cannot finalize already settled auction");
    _finalizeAuction(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice Returns the minimum amount a bidder must spend to participate in an auction.
* Bids must be greater than or equal to this value or they will revert.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return minimum The minimum amount for a bid to be accepted.
****************************************************************************************************/
  function getMinBidAmount(address nftContract, uint256 tokenId) external view returns (uint256 minimum) {
    AuctionData storage auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

/***************************************************************************************************
* @notice Returns the auctionID for a given NFT, or 0 if no auction is found.
* @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return auction AuctionData struct for the given NFT.
****************************************************************************************************/
  function getAuctionData(address nftContract, uint256 tokenId) external view returns (AuctionData memory auction) {
    return nftContractTokenIdToAuctionData[nftContract][tokenId];
  }

/***************************************************************************************************
* @notice Settle an auction that has already ended.
* This will send the NFT to the highest bidder and distribute revenue for this sale.
****************************************************************************************************/
  function _finalizeAuction(address nftContract, uint256 tokenId) private {
    AuctionData memory auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    require(auction.endTime < block.timestamp, "MarketAuction: Cannot finalize auction in progress");
    // Remove the auction.
    delete nftContractTokenIdToAuctionData[nftContract][tokenId];

    _transferFromMarket(nftContract, tokenId, auction.bidder);
    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee) = _distributeFunds(nftContract, tokenId, auction.amount, auction.marketFee);

    emit AuctionFinalized(nftContract, tokenId, auction.seller, auction.bidder, auction.amount, mssFee, creatorFee);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev If it is checked whether it is registered in another sales method, it will be invalidated.
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal virtual override {
    require(nftContractTokenIdToAuctionData[nftContract][tokenId].seller == address(0), "MarketAuction: Active auction");
    
    super._checkRegisteredMarket(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./MarketCore.sol";
import "./MarketFees.sol";
//import "./ErrorMessage.sol";

import "../Utils/SupportsInterfaces.sol";

/***************************************************************************************************
* @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
* @notice NFTs with a buy price set are escrowed in the market contract.
****************************************************************************************************/
abstract contract MarketFixedPrice is MarketCore, SupportsInterfaces, MarketFees {
  using AddressUpgradeable for address payable;
  using StringsUpgradeable for uint256;

/***************************************************************************************************
* @notice Stores the buy price details for a specific NFT.
* @dev The struct is packed into a single slot to optimize gas.
****************************************************************************************************/
  struct FixedPrice {
    address payable seller; // The current owner of this NFT which set a buy price. A zero price is acceptable so a non-zero address determines whether a price has been set.
    uint256 startTime;      // BUY Save in the form of unix timestamp.
    uint256 price;          // The current buy price set for this NFT.
    uint16 marketFee;       // Market fee
  }

  mapping(address => mapping(uint256 => FixedPrice)) private nftContractToTokenIdToFixedPrice; // Stores the current buy price for each NFT.

/***************************************************************************************************
* @notice Emitted when an NFT is bought by accepting the buy price,
* indicating that the NFT has been transferred and revenue from the sale distributed.
* @dev The total buy price that was accepted is `mssFee` + `creatorFee` + `ownerRev`.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param buyer The address of the collector that purchased the NFT using `buy`.
* @param seller The address of the seller which originally set the buy price.
* @param value The amount of ETH that was transferred to the collector.
* @param mssFee The amount of ETH that was sent to market for this sale.
* @param creatorFee The amount of ETH that was sent to the creator for this sale.
****************************************************************************************************/
  event FixedPriceSold(address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 value, uint256 mssFee, uint256 creatorFee);
/***************************************************************************************************
* @notice Emitted when the buy price is removed by the owner of an NFT.
* @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
* e.g. listed for sale in an auction.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param reason The reason for the cancellation.
****************************************************************************************************/
  event FixedPriceCanceled(address indexed nftContract, uint256 indexed tokenId, string reason);
/***************************************************************************************************
* @notice Emitted when a buy price is set by the owner of an NFT.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param seller The address of the NFT owner which set the buy price.
* @param price The price of the NFT.
****************************************************************************************************/
  event FixedPriceSet(address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
/***************************************************************************************************
* @notice Buy the NFT at the set buy price.
* when the price is reduced (and any surplus funds provided are refunded).
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function FixedPriceBuy(address nftContract, uint256 tokenId) external payable {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    
    require(fixedPrice.startTime <= block.timestamp, "MarketFixedPrice: startTime is not yet reached");
    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot buy unset price");
    require(fixedPrice.seller != msg.sender, "MarketFixedPrice: Cannot buy own FixedPrice");
   
    _buy(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice Removes the buy price set for an NFT.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function adminCancelFixedPrice(address nftContract, uint256 tokenId, string calldata reason) external onlyAdmin {
    require(bytes(reason).length != 0, "MarketFixedPrice: Cannot admin cancel without reason");

    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot cancel unset price"); // This check is redundant with the next one, but done in order to provide a more clear error message.
    // Remove the buy price
    delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];
  
    emit FixedPriceCanceled(nftContract, tokenId, reason);
  }

/***************************************************************************************************
* @notice Sets the buy price for an NFT.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param price The price at which someone could buy this NFT.
****************************************************************************************************/
  function createFixedPrice(address nftContract, uint256 tokenId, address seller, uint256 price, uint256 startUnixTime, uint16 marketFee) external onlyAdmin {
    require(price > 0, "MarketFixedPrice: Cannot set price of 0");
    if (MIN_MARKET_FEE_POINTS > marketFee || marketFee > MAX_MARKET_FEE_POINTS) {
      revert(string(abi.encodePacked("MarketAuction: The market fees are between ",
           uint256(MIN_MARKET_FEE_POINTS).toString(), " to ", uint256(MAX_MARKET_FEE_POINTS).toString())));
    }
    _checkRegisteredMarket(nftContract, tokenId);
    // Check that this contract is the owner, and if you are not the owner, revert
    require(address(this) == _getInterfacesOwnerOf(nftContract, tokenId), "MarketFixedPrice: Only NFT contract owner can create auction");

    // If there is no royalty information, revert
    (address checkRoyaltyInfo,) = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    require(checkRoyaltyInfo != address(0), "MarketFixedPrice: Royalty info not found");

    // Store the new price for this NFT.
    nftContractToTokenIdToFixedPrice[nftContract][tokenId] = FixedPrice(payable(seller), startUnixTime, price, marketFee);

    emit FixedPriceSet(nftContract, tokenId, seller, price);
  }

/***************************************************************************************************
* @notice Returns the buy price details for an NFT if one is available.
* @dev If no price is found, seller will be address(0) and price will be max uint256.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @returns fixedPrice FixedPrice struct the given NFT.
****************************************************************************************************/
  function getFixedPrice(address nftContract, uint256 tokenId) external view returns (FixedPrice memory fixedPrice) {
    return nftContractToTokenIdToFixedPrice[nftContract][tokenId];
  }

/***************************************************************************************************
* @notice Process the purchase of an NFT at the current buy price.
* @dev The caller must confirm that the seller != address(0) before calling this function.
****************************************************************************************************/
  function _buy(address nftContract, uint256 tokenId) private nonReentrant {
    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.price <= msg.value, "MarketFixedPrice: Cannot buy at lower price");
    // Remove the buy now price
    delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    // Transfer the NFT to the buyer.
    // This should revert if the `msg.sender` is not the owner of this NFT.
    _transferFromMarket(nftContract, tokenId, msg.sender);
    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee) = _distributeFunds(nftContract, tokenId, msg.value, fixedPrice.marketFee);

    emit FixedPriceSold(nftContract, tokenId, fixedPrice.seller, msg.sender, msg.value, mssFee, creatorFee);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev If it is checked whether it is registered in another sales method, it will be invalidated.
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal virtual override {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.seller == address(0), "MarketFixedPrice: Active buy now");
    
    super._checkRegisteredMarket(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketCore.sol";

import "../Utils/AdminTreasury.sol";
import "../Utils/Constants.sol";
import "../Utils/SupportsInterfaces.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/***************************************************************************************************
* @title A mixin to distribute funds when an NFT is sold.
****************************************************************************************************/
abstract contract MarketFees is Constants, Initializable, AdminTreasury, MarketCore, SupportsInterfaces, SendValueWithFallbackWithdraw {
  using AddressUpgradeable for address payable;
  
/***************************************************************************************************
* @notice Distributes funds to market, creator recipients, and NFT owner after a sale.
****************************************************************************************************/
  function _distributeFunds(address nftContract, uint256 tokenId, uint256 price, uint16 sendMarketFee) internal
    returns (uint256 marketFee, uint256 creatorFee) {
    address payable creatorRecipient;
    (marketFee, creatorRecipient, creatorFee) = _getFees(nftContract, tokenId, price, sendMarketFee);

    _sendValueWithFallbackWithdraw(nftContract, tokenId, treasury, marketFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    if (creatorFee > 0 && creatorRecipient != address(0)) {
      _sendValueWithFallbackWithdraw(nftContract, tokenId, creatorRecipient, creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
    } else {
      revert("MarketFees: No creator fee to distribute");
    }
  }

/***************************************************************************************************
* @dev Calculates how funds should be distributed for the given sale details.
****************************************************************************************************/
  function _getFees(address nftContract, uint256 tokenId, uint256 price, uint16 sendMarketFee) private view
    returns (uint256 marketFee, address payable creatorRecipient, uint256 creatorRev) {
    // Bring the amount to be paid to the seller from the royalty address
    (creatorRecipient,) = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    require(creatorRecipient != address(0), "MarketFees: Creator recipient is not set");
    // Calculate the market fee
    marketFee = (price * sendMarketFee) / BASIS_POINTS;
    creatorRev = price - marketFee;
  }

/***************************************************************************************************
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../Interfaces/IMSAdmin.sol";

/***************************************************************************************************
* @title Wallet address and administrator account management to receive fees
****************************************************************************************************/
abstract contract AdminTreasury is Initializable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;

  address payable public treasury; // The address of the treasury contract.
  address public contractAdmin; // The address of the admin contract.

/***************************************************************************************************
* @notice Manager check
****************************************************************************************************/  
  modifier onlyAdmin() {
    require(IMSAdmin(contractAdmin).isAdmin(msg.sender), "Admin: Only the admin can call this function");
    _;
  }

/***************************************************************************************************
* @notice Administrator address setting initialization
****************************************************************************************************/  
  function _initializeAdminTreasury(address _contractAdmin, address payable _treasury) internal onlyInitializing {
    require(_contractAdmin.isContract(), "AdminTreasury: The contract admin address must be a contract");
    require(!_treasury.isContract(), "AdminTreasury: The treasury address should not be a contract");
    
    contractAdmin = _contractAdmin;
    treasury = _treasury;
  }

/***************************************************************************************************
* @notice Set Treasury address.
****************************************************************************************************/
  function setTreasury(address payable _treasury) onlyAdmin external {
    require(!_treasury.isContract(), "AdminTreasury: The treasury address should not be a contract");
    treasury = _treasury;
  }

/***************************************************************************************************
* @notice Set Admin address.
****************************************************************************************************/
  function setAdmin(address _contractAdmin) onlyAdmin external {
    require(_contractAdmin.isContract(), "AdminTreasury: The contract admin address must be a contract");
    contractAdmin = _contractAdmin;
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/***************************************************************************************************
* @title Constant values shared across mixins.
****************************************************************************************************/
abstract contract Constants {
  
  /// @notice 100% in basis points.
  uint256 internal constant BASIS_POINTS = 10000;
    /// @notice 마켓 수수료 최소 값
  uint16 internal constant MIN_MARKET_FEE_POINTS = 100; // 1%
  /// @notice 마켓 수수료 최대 값
  uint16 internal constant MAX_MARKET_FEE_POINTS = 5000; // 50%
  /// @notice 기본 마켓 수수료
  uint16 internal constant DEFAULT_MARKET_FEE_POINTS = 500; // 5%
  /// @notice 기본 로열티 수수료
  uint16 internal constant DEFAULT_ROYALTY_FEE_POINTS = 1000; // 10%

  /// @notice The minimum increase of 10% required when making an offer or placing a bid.
  uint16 internal constant MIN_PERCENT_INCREMENT_IN_POINTS = 1000; // 10%
  /// @notice If the amount of adaptation is more than 1ETH, the bid amount increases by 5%
  uint16 internal constant MAX_PERCENT_INCREMENT_IN_POINTS = 500; // 5%

  /// @notice The gas limit to send ETH to multiple recipients, enough for a 5-way split.
  uint256 internal constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

  /// @notice The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
  uint256 internal constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 internal constant EXTENSION_DURATION = 10 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 internal constant MAX_DURATION = 1000 days;
  /// @notice 오퍼 제안 시간 (FixedPrice 제안 시간 + 오퍼 제안 시간 으로 설정됨)
  uint256 internal constant DURATION_OFFER = 24 hours;
  
  /// @notice 판매 시작 금액
  uint256 internal constant MIN_START_PRICE = 0.01 ether;
  /// @notice Offer 최소 제안 가격 증가 값
  uint256 internal constant MIN_INCREMENT_OFFER = 0.001 ether;

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

/***************************************************************************************************
* @title A mixin for sending ETH with a fallback withdraw mechanism.
* @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
* for future withdrawal instead.
****************************************************************************************************/
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

  //address[] pendingWithdrawAddress;
  //mapping(address => uint256) private pendingWithdrawals; // Tracks the amount of ETH that is stored in escrow for future withdrawal.
  EnumerableMapUpgradeable.AddressToUintMap pendingWithdrawals;
  
/***************************************************************************************************
* @notice Emitted when an attempt to send ETH fails or runs out of gas and the value is stored in escrow instead.
* @param nftContract The address of the NFT contract.
* @param tokenId The ID of the token.
* @param user The account which has escrowed ETH to withdraw.
* @param amount The amount of ETH which has been added to the user's escrow balance.
****************************************************************************************************/
  event WithdrawPending(address indexed nftContract, uint256 indexed tokenId, address user, uint256 amount);
/***************************************************************************************************
* @notice Emitted when escrowed funds are withdrawn.
* @param user The account which has withdrawn ETH.
* @param amount The amount of ETH which has been withdrawn.
****************************************************************************************************/
  event Withdrawal(address indexed user, uint256 amount);
/***************************************************************************************************
* @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
****************************************************************************************************/
  function withdraw() external {
    withdrawFor(payable(msg.sender));
  }

/***************************************************************************************************
* @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
* @param user The account which has escrowed ETH to withdraw.
****************************************************************************************************/
  function withdrawFor(address payable user) public nonReentrant {
    (, uint256 amount) = pendingWithdrawals.tryGet(user);
    require(amount != 0, "SendValueWithFallbackWithdraw: No Funds Available"); 
    
    pendingWithdrawals.remove(user);
    user.sendValue(amount);
    
    emit Withdrawal(user, amount);
  }

/***************************************************************************************************
* @notice Withdrawal to all those who will be withdrawn
****************************************************************************************************/
  function _withdrawAll(uint256 gasLimit) internal nonReentrant {
    uint256 withdrawCount = pendingWithdrawals.length();
    for (uint256 i = 0; i < withdrawCount; i++) {
      (address user, uint256 amount) = pendingWithdrawals.at(0);
      pendingWithdrawals.remove(user);
      
      (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
      if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
        unchecked {
          (, uint256 originalAmount) = pendingWithdrawals.tryGet(user);
          pendingWithdrawals.set(user, originalAmount + amount);
        }
        emit WithdrawPending(address(0), 0, user, amount);
        break; // 일단 멈추자
      } else {
        emit Withdrawal(user, amount);
      }
    }
  }

/***************************************************************************************************
* @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
****************************************************************************************************/
  function _sendValueWithFallbackWithdraw(address nftContract, uint256 tokenId, address payable user, uint256 amount, uint256 gasLimit) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      unchecked {
        (, uint256 originalAmount) = pendingWithdrawals.tryGet(user);
        pendingWithdrawals.set(user, originalAmount + amount);
      }
      
      emit WithdrawPending(nftContract, tokenId, user, amount);
    }
  }

/***************************************************************************************************
* @notice Returns how much funds are available for manual withdraw due to failed transfers.
* @param user The account to check the escrowed balance of.
* @return balance The amount of funds which are available for withdrawal for the given user.
****************************************************************************************************/
  function getPendingWithdrawal(address user) external view returns (uint256 balance) {
    (, balance) = pendingWithdrawals.tryGet(user);
    return balance;
  }

/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************/
  function getPendingWithdrawalCount() external view returns (uint256 count) {
    return pendingWithdrawals.length();
  }

/***************************************************************************************************
* @notice Return to withdrawal
* @return balance This is the amount you need to withdraw.
****************************************************************************************************/
  function getPendingWithdrawalAmount() external view returns (uint256 balance) {
    for (uint256 i = 0; i < pendingWithdrawals.length(); i++) {
      (, uint256 amount) = pendingWithdrawals.at(i);
      balance += amount;
    }
    return balance;
  }

/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************
  function getPendingWithdrawalIndex(uint256 index) external view returns (address user, uint256 amount) {
    (user, amount) = pendingWithdrawals.at(index);
    return (user, amount);
  }
/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************
  function getPendingWithdrawalIndexRemove(uint256 index) public {
    (address user, ) = pendingWithdrawals.at(index);
    pendingWithdrawals.remove(user);
  }
/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************
  function getPendingWithdrawalIndexRemoveSet(uint256 index) public {
    (address user, uint256 amount) = pendingWithdrawals.at(index);
    pendingWithdrawals.remove(user);

    (, uint256 originalAmount) = pendingWithdrawals.tryGet(user);
    pendingWithdrawals.set(user, originalAmount + amount);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./Constants.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "../../Interfaces/IMSTokens.sol";

/***************************************************************************************************
* @title Interface for other contracts
****************************************************************************************************/
abstract contract SupportsInterfaces is Constants, ReentrancyGuardUpgradeable { // Adding this unused mixin to help with linearization 
  using ERC165CheckerUpgradeable for address;

/***************************************************************************************************
* @notice Looks up the royalty payment configuration for a given NFT.
****************************************************************************************************/
  function _getInterfacesCreatorPaymentInfo(address nftContract, uint256 tokenId) internal view returns (address payable recipient, uint256 royaltyPoints) {
    // 1st priority: ERC-2981
    if (nftContract.supportsInterface(type(IERC2981Upgradeable).interfaceId)) {
      (address receiver, uint256 points) = IERC2981Upgradeable(nftContract).royaltyInfo(tokenId, BASIS_POINTS);
      if (receiver != address(0)) {
        recipient = payable(receiver);
        royaltyPoints = points;
      }
    }
    return (recipient, royaltyPoints);
  }

/***************************************************************************************************
* @notice NFT Owner
****************************************************************************************************/
  function _getInterfacesOwnerOf(address nftContract, uint256 tokenId) internal view returns (address tokenOwner) {
    if (nftContract.supportsInterface(type(IERC721Upgradeable).interfaceId)) {
      tokenOwner = IERC721Upgradeable(nftContract).ownerOf(tokenId);
    } else {
      revert("supportsInterface: The contract is not ERC721");
    }
  }

/***************************************************************************************************
* @notice If it is MOSAIC SQUARE NFT, use the corresponding interface to call the TransferFrom function.
****************************************************************************************************/
  function _getInterfacestransferTo2ndMarket(address nftContract, uint256 tokenId) internal returns (bool) {
    if (nftContract.supportsInterface(type(IMSTokens).interfaceId)) {
      IMSTokens(nftContract).transferTo2ndMarket(msg.sender, tokenId);
      return true;
    }
    return false;
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMSAdmin{
    function isAdmin(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMSTokens{
    function transferTo2ndMarket(address from, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}