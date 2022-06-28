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
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Utils/Admin.sol";
import "./Utils/MarketCore.sol";
import "./Utils/SendValueWithFallbackWithdraw.sol";

import "./Market/Auction.sol";
import "./Market/FixedPrice.sol";

/**
 * @title A market for MosaicSquare.
 * @notice Notice 테스트 한글 123
 * @dev 주석 주석 Code size is 26679 bytes
 */
contract MSS1stMarket is Initializable, Admin, MarketCore, ReentrancyGuardUpgradeable, SendValueWithFallbackWithdraw, MarketAuction, MarketFixedPrice {

  // constructor(address payable _treasury) Admin(_treasury) {}
  constructor() {}

  /**
  * @notice Called once to configure the contract after the initial proxy deployment.
  * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
  */
  function initialize(address payable _treasury) external initializer {
    _initializeAuctionID();
    _initializeTreasury(_treasury);
  }

 /**
  * @inheritdoc MarketCore
  * @dev This is a no-op function required to avoid compile errors.
  */
  function _checkActiveMarket(address nftContract, uint256 tokenID) internal override(MarketCore, MarketAuction, MarketFixedPrice) {
    super._checkActiveMarket(nftContract, tokenID); 
  }

 /**
  * @dev 1차 마켓에서 판매된 상품인지 확인
  * @param nftContract 주소
  * @param tokenID  토큰 ID
  * @return _isFirstSale  결과
  */
  function getFirstSale(address nftContract, uint256 tokenID) external view returns (bool _isFirstSale) {
    _isFirstSale = _getNFTContractToTokenIDFirstSale(nftContract, tokenID);
  }

 /**
  * @notice NFT 토큰 돌려주기
  * 판매자에게 돌려주기
  * @param nftContract 주소
  * @param tokenID  토큰 ID
  * @param seller 판매자 주소
  */
  function returnNFT(address nftContract, uint256 tokenID, address seller) external onlyAdmin {
    _checkActiveMarket(nftContract, tokenID); // 마켓에 등록되어있다면 에러를 발생시킨다.
    _transferFromMarket(nftContract, tokenID, seller);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title 수수료를 받을 지갑 주소와 관리자 계정 관리
 */
abstract contract Admin is Initializable {
  using AddressUpgradeable for address payable;

  /// @notice The address of the treasury contract.
  address payable public treasury;

  /// @notice 관리자 체크
  modifier onlyAdmin() {
    require(msg.sender == treasury, "Admin: Only the admin can call this function");
    _;
  }

  // @notice 컨트랙트 생성시 관리자 주소 설정
  /*constructor(address payable _treasury) {
    require(!_treasury.isContract(), "Admin: Treasury address is a contract");
    treasury = _treasury;
  }*/

  // @notice 관리자 주소 설정 초기화 함수
  function _initializeTreasury(address payable _treasury) internal onlyInitializing {
    require(!_treasury.isContract(), "Admin: Treasury address is a contract");
    treasury = _treasury;
  }
 /**
  * @notice Set Treasury address.
  */
  function setTreasury(address payable _treasury) external {
    require(!_treasury.isContract(), "Admin: Treasury address is a contract");
    treasury = _treasury;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./Constants.sol";

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract MarketCore is Constants {
  using AddressUpgradeable for address;

  /// @notice Track if there has been a sale for the NFT in this market previously.
  mapping(address => mapping(uint256 => bool)) private _nftContractToTokenIDToFirstSaleCompleted;
  
  /**
   * @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromMarket(address nftContract, uint256 tokenID, address recipient) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenID);
  }
  /**
   * @notice 해당 NFT가 등록되어있는지 확인
   */
  function _checkActiveMarket(address nftContract, uint256 tokenID) internal virtual {}
  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount * MIN_PERCENT_INCREMENT_IN_BASIS_POINTS;
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
  /**
   * @notice 첫 판매 관련 확인 및 등록을 위한 함수입니다
   */
  function _getNFTContractToTokenIDFirstSale(address nftContract, uint256 tokenID) internal view returns (bool) {
    return _nftContractToTokenIDToFirstSaleCompleted[nftContract][tokenID];
  }
  function _setNFTContractToTokenIDFirstSale(address nftContract, uint256 tokenID) internal {
    _nftContractToTokenIDToFirstSaleCompleted[nftContract][tokenID] = true;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[950] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;

  /// @dev Tracks the amount of ETH that is stored in escrow for future withdrawal.
  mapping(address => uint256) private pendingWithdrawals;
  /**
   * @notice Emitted when an attempt to send ETH fails or runs out of gas and the value is stored in escrow instead.
   * @param user The account which has escrowed ETH to withdraw.
   * @param amount The amount of ETH which has been added to the user's escrow balance.
   */
  event WithdrawPending(address indexed user, uint256 amount);
  /**
   * @notice Emitted when escrowed funds are withdrawn.
   * @param user The account which has withdrawn ETH.
   * @param amount The amount of ETH which has been withdrawn.
   */
  event Withdrawal(address indexed user, uint256 amount);
  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
   */
  function withdraw() external {
    withdrawFor(payable(msg.sender));
  }
  /**
   * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
   * @param user The account which has escrowed ETH to withdraw.
   */
  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = pendingWithdrawals[user];
    require(amount != 0, "SendValueWithFallbackWithdraw: No Funds Available"); 
    
    pendingWithdrawals[user] = 0;
    user.sendValue(amount);
    
    emit Withdrawal(user, amount);
  }
  /**
   * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
   */
  function _sendValueWithFallbackWithdraw(address payable user, uint256 amount, uint256 gasLimit) internal {
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
        pendingWithdrawals[user] += amount;
      }
      
      emit WithdrawPending(user, amount);
    }
  }
  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   * @param user The account to check the escrowed balance of.
   * @return balance The amount of funds which are available for withdrawal for the given user.
   */
  function getPendingWithdrawal(address user) external view returns (uint256 balance) {
    return pendingWithdrawals[user];
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[499] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../Utils/Admin.sol";
import "../Utils/Constants.sol";
import "../Utils/MarketCore.sol";
import "../Utils/MarketFees.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";
import "../Utils/SupportsInterfaces.sol";

/**
 * @title A market for MosaicSquare.
 * @notice Notice 테스트 한글 123
 * @dev 주석 주석
 */
abstract contract MarketAuction is Constants, Initializable, Admin, MarketCore, ReentrancyGuardUpgradeable, SupportsInterfaces, SendValueWithFallbackWithdraw, MarketFees {
  using AddressUpgradeable for address payable;
  
  /// @notice Stores the auction configuration for a specific NFT.
  struct AuctionData {
    /// @notice The address of the NFT contract.
    address nftContract;
    /// @notice The id of the NFT.
    uint256 tokenID;
    /// @notice The owner of the NFT which listed it in auction.
    address payable seller;
    /// @notice 경매 시작 시간 Unix timestamp 형태로 저장. 0이면 사용 안함
    /// @dev 예외 처리로 생각해 볼게 많음 유저가 옥션을 만든다고 하면 유저가 보낸 이 값을 어떻게 보장하지...?
    uint256 startTime;
    /// @notice 첫 비딩 이후 경매 기간 설정 값
    uint256 duration;
    /// @notice The time at which this auction will not accept any new bids.
    /// @dev This is `0` until the first bid is placed.
    uint256 endTime;
    /// @notice 마켓 수수료
    uint16 marketFee;
    /// @notice The current highest bidder in this auction.
    /// @dev This is `address(0)` until the first bid is placed.
    address payable bidder;
    /// @notice The latest price of the NFT in this auction.
    /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
    uint256 amount;
  }

  /// @notice A global id for auctions of any type.
  uint256 private nextAuctionID;
  /// @notice The auction configuration for a specific auction id.
  mapping(address => mapping(uint256 => uint256)) private nftContractTokenIDToAuctionID;
  /// @notice The auction id for a specific NFT.
  /// @dev This is deleted when an auction is finalized or canceled.
  mapping(uint256 => AuctionData) private auctionIDToAuction;

 /**
  * @notice Emitted when a bid is placed.
  * @param auctionID The id of the auction this bid was for.
  * @param bidder The address of the bidder.
  * @param amount The amount of the bid.
  * @param endTime The new end time of the auction (which may have been set or extended by this bid).
  */
  event AuctionBidPlaced(uint256 indexed auctionID, address indexed bidder, uint256 amount, uint256 endTime);
/**
  * @notice Emitted when an auction is cancelled.
  * @dev This is only possible if the auction has not received any bids.
  * @param auctionID The id of the auction that was cancelled.
  */
  event AuctionCanceled(uint256 indexed auctionID, string reason);
 /**
  * @notice Emitted when an NFT is listed for auction.
  * @param seller The address of the seller.
  * @param nftContract The address of the NFT
  * @param tokenID The id of the NFT.
  * @param duration The duration of the auction (always 24-hours).
  * @param extensionDuration The duration of the auction extension window (always 15-minutes).
  * @param reservePrice The reserve price to kick off the auction.
  * @param auctionID The id of the auction that was created.
  */
  event AuctionCreated(address indexed seller, address indexed nftContract, uint256 indexed tokenID, uint256 duration, uint256 extensionDuration, uint256 reservePrice, uint256 auctionID);
 /**
  * @notice Auction price updated.
  * @param auctionID The id of the auction that was updated.
  * @param beforAmount The previous price of the NFT.
  * @param afterAmount The new price of the NFT.
  */
  event AuctionPriceUpdated(uint256 indexed auctionID, uint256 beforAmount, uint256 afterAmount);
/**
  * @notice Auction duration updated.
  * @param auctionID The id of the auction that was updated.
  * @param beforDuration The previous duration of the auction.
  * @param afterDuration The new duration of the auction.
  */
  event AuctionDurationUpdated(uint256 indexed auctionID, uint256 beforDuration, uint256 afterDuration);
 /**
  * @notice Emitted when an auction that has already ended is finalized, 
  * indicating that the NFT has been transferred and revenue from the sale distributed.
  * @dev The amount of the highest bid / final sale price for this auction is `mssFee` + `creatorFee` + `ownerRev`.
  * @param auctionID The id of the auction that was finalized.
  * @param seller The address of the seller.
  * @param bidder The address of the highest bidder that won the NFT.
  * @param mssFee The amount of ETH that was sent to market for this sale.
  * @param creatorFee The amount of ETH that was sent to the creator for this sale.
  * @param ownerRev The amount of ETH that was sent to the owner for this sale.
  */
  event AuctionFinalized(uint256 indexed auctionID, address indexed seller, address indexed bidder, uint256 mssFee, uint256 creatorFee, uint256 ownerRev);
 /**
  * @notice Emitted when an auction is invalidated due to other market activity.
  * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
  * @param auctionID The id of the auction that was invalidated.
  */
  event AuctionInvalidated(uint256 indexed auctionID);
  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This sets the initial auction id to 1, making the first auction cheaper
   * and id 0 represents no auction found.
   */
  function _initializeAuctionID() internal onlyInitializing {
    nextAuctionID = 1;
  }
  /**
   * @notice Allows market to cancel an auction, refunding the bidder
   * @param auctionID The id of the auction to cancel.
   * @param reason The reason for the cancellation (a required field).
   */
  function adminCancelAuction(uint256 auctionID, string calldata reason) external onlyAdmin {
    require(bytes(reason).length != 0, "MarketAuction: Cannot admin cancel without reason");
    
    AuctionData memory auction = auctionIDToAuction[auctionID];

    require(auction.amount != 0, "MarketAuction: Cannot cancel nonexistent auction");
    
    delete nftContractTokenIDToAuctionID[auction.nftContract][auction.tokenID];
    delete auctionIDToAuction[auctionID];

    if (auction.bidder != address(0)) {
      // Refund the highest bidder if any bids were placed in this auction.
      _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionCanceled(auctionID, reason);
  }
  /**
   * @notice Creates an auction for the given NFT.
   * 이 동작을 하기 전 NFT 소유주는 마켓이여야 합니다.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @param auctionPrice The initial reserve price for the auction.
   */
  function createAuction(address nftContract, uint256 tokenID, address seller, uint256 auctionPrice, uint256 startUnixTime, uint256 duration, uint16 marketFee) external onlyAdmin {
    require(auctionPrice != 0, "MarketAuction: Price must be greater than 0");
    require(!_getNFTContractToTokenIDFirstSale(nftContract, tokenID), "MarketAuction: NFTs first sold");
    require(duration >= EXTENSION_DURATION, "MarketAuction: Duration must be at least 15 minutes");

    if (MIN_MARKET_FEE_BASIS_POINTS > marketFee || marketFee > MAX_MARKET_FEE_BASIS_POINTS) {
      revert(ERROR_MARKET_AUCTION_ARGUMENTS);
    }
    
    _checkActiveMarket(nftContract, tokenID);

    // 이 컨트랙트가 소유자인지 확인하고 소유자가 아니면 에러
    require(address(this) == _getInterfacesOwnerOf(nftContract, tokenID), "MarketAuction: Only NFT contract owner can create auction");

    // 원작자 확인 NFTContract.TokenCreator(uint256 tokenID)
    address tokenCreator = _getInterfacesTokenCreator(nftContract, tokenID);
    if (tokenCreator != address(0)) {
      require(tokenCreator == seller, "MarketAuction: Only token creator can create auction");
    }
    
    uint256 auctionID = nextAuctionID++;
    
    if (startUnixTime == 0) {
      startUnixTime = block.timestamp;
    }

    // Store the auction details
    nftContractTokenIDToAuctionID[nftContract][tokenID] = auctionID;
    auctionIDToAuction[auctionID] = AuctionData(nftContract, tokenID,
      payable(seller), startUnixTime, duration, 0, // endTime is only known once the reserve price is met
      marketFee, payable(0), // bidder is only known once a bid has been placed
      auctionPrice
    );

    emit AuctionCreated(tokenCreator, nftContract, tokenID, duration, EXTENSION_DURATION, auctionPrice, auctionID);
  }
  /**
  * @notice Place a bid in an auction.
  * A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
  * If this is the first bid on the auction, the countdown will begin.
  * If there is already an outstanding bid, the previous bidder will be refunded at this time
  * and if the bid is placed in the final moments of the auction, the countdown may be extended.
  * @param auctionID The id of the auction to bid on.
  */
  function placeBid(uint256 auctionID) external payable {
    AuctionData storage auction = auctionIDToAuction[auctionID];
    require(auction.seller != address(0), "MarketAuction: Cannot bid on nonexistent auction");
    require(auction.startTime <= block.timestamp, "MarketAuction: Cannot bid on an auction that has not been started");
    require(auction.seller != msg.sender, "MarketAuction: Cannot bid on your own auction");

    if (auction.endTime == 0) {
      // This is the first bid, kicking off the auction.
      require(auction.amount <= msg.value, "MarketAuction: Cannot bid lower than reserve price");

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
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
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
      _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionBidPlaced(auctionID, msg.sender, msg.value, auction.endTime);
  }
  /**
   * @notice updates the auction price
   * @param auctionID The id of the auction to updates the auction.
   * @param auctionPrice The new auction price.
   */
  function updateAuctionPrice(uint256 auctionID, uint256 auctionPrice) external onlyAdmin {
    require(auctionID != 0, ERROR_MARKET_AUCTION_ARGUMENTS);
    require(auctionPrice != 0, ERROR_MARKET_AUCTION_ARGUMENTS);
    
    AuctionData storage auction = auctionIDToAuction[auctionID];
    
    require(auction.seller != address(0), "MarketAuction: Cannot update nonexistent auction");
    require(auction.endTime == 0, "MarketAuction: Auctions with bids cannot be changed.");
    require(auction.amount != auctionPrice, "MarketAuction: Cannot update to the same price");

    uint256 originalAmount = auction.amount;
    auction.amount = auctionPrice;

    emit AuctionPriceUpdated(auctionID, originalAmount, auction.amount);
  }
  /**
   * @notice updates the auction duration
   * @param auctionID The id of the auction to updates the auction.
   * @param duration The new duration.
   */
  function updateAuctionDuration(uint256 auctionID, uint256 duration) external onlyAdmin {
    require(auctionID != 0, ERROR_MARKET_AUCTION_ARGUMENTS);
    require(duration >= EXTENSION_DURATION, ERROR_MARKET_AUCTION_ARGUMENTS);
    
    AuctionData storage auction = auctionIDToAuction[auctionID];
    
    require(auction.seller != address(0), "MarketAuction: Cannot update nonexistent auction");
    require(auction.endTime == 0, "MarketAuction: Auctions with bids cannot be changed.");
    require(auction.duration != duration, "MarketAuction: Cannot update duration to the same value");

    uint256 originalDuration = auction.duration;
    auction.duration = duration;

    emit AuctionDurationUpdated(auctionID, originalDuration, auction.duration);
  }
 /**
  * @notice Once the countdown has expired for an auction, anyone can settle the auction.
  * This will send the NFT to the highest bidder and distribute revenue for this sale.
  * @param auctionID The id of the auction to settle.
  */
  function finalizeAuction(uint256 auctionID) external nonReentrant {
    require(auctionIDToAuction[auctionID].endTime != 0, "MarketAuction: Cannot finalize already settled auction");
    _finalizeAuction(auctionID);
  }
  /**
  * @notice Settle an auction that has already ended.
  * This will send the NFT to the highest bidder and distribute revenue for this sale.
  */
  function _finalizeAuction(uint256 auctionID) private {
    AuctionData memory auction = auctionIDToAuction[auctionID];
    require(auction.endTime < block.timestamp, "MarketAuction: Cannot finalize auction in progress");
    // Remove the auction.
    delete nftContractTokenIDToAuctionID[auction.nftContract][auction.tokenID];
    delete auctionIDToAuction[auctionID];

    _transferFromMarket(auction.nftContract, auction.tokenID, auction.bidder);
    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(auction.nftContract, auction.tokenID, auction.seller, auction.amount, auction.marketFee);

    emit AuctionFinalized(auctionID, auction.seller, auction.bidder, mssFee, creatorFee, ownerRev);
  }
 /**
  * @inheritdoc MarketCore
  * @dev If it is checked whether it is registered in another sales method, it will be invalidated.
  */
  function _checkActiveMarket(address nftContract, uint256 tokenID) internal virtual override {
    uint256 auctionID = nftContractTokenIDToAuctionID[nftContract][tokenID];
    require(auctionID == 0, "MarketAuction: Active auction");
    super._checkActiveMarket(nftContract, tokenID);
  }
 /**
  * @notice Returns the minimum amount a bidder must spend to participate in an auction.
  * Bids must be greater than or equal to this value or they will revert.
  * @param auctionID The id of the auction to check.
  * @return minimum The minimum amount for a bid to be accepted.
  */
  function getMinBidAmount(uint256 auctionID) external view returns (uint256 minimum) {
    AuctionData storage auction = auctionIDToAuction[auctionID];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }
  /**
   * @notice Returns auction details for a given auctionID.
   * @param auctionID The id of the auction to lookup.
   * @return auction The auction details.
   */
  function getAuctionData(uint256 auctionID) external view returns (AuctionData memory auction) {
    return auctionIDToAuction[auctionID];
  }
 /**
  * @notice Returns the auctionID for a given NFT, or 0 if no auction is found.
  * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
  * @param nftContract The address of the NFT contract.
  * @param tokenID The id of the NFT.
  * @return auctionID The id of the auction, or 0 if no auction is found.
  */
  function getAuctionDataID(address nftContract, uint256 tokenID) external view returns (uint256 auctionID) {
    return nftContractTokenIDToAuctionID[nftContract][tokenID];
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../Utils/MarketCore.sol";
import "../Utils/MarketFees.sol";
import "../Utils/SupportsInterfaces.sol";

/**
 * @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
 * @notice NFTs with a buy price set are escrowed in the market contract.
 */
abstract contract MarketFixedPrice is MarketCore, SupportsInterfaces, MarketFees {
  using AddressUpgradeable for address payable;

  /// @notice Stores the buy price details for a specific NFT.
  /// @dev The struct is packed into a single slot to optimize gas.
  struct FixedPrice {
    /// @notice The current owner of this NFT which set a buy price.
    /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
    address payable seller;
    /// @notice The current buy price set for this NFT.
    uint96 price;
    /// @notice 마켓 수수료
    uint16 marketFee;
  }

  /// @notice Stores the current buy price for each NFT.
  mapping(address => mapping(uint256 => FixedPrice)) private nftContractToTokenIDToFixedPrice;

  /**
   * @notice Emitted when an NFT is bought by accepting the buy price,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The total buy price that was accepted is `mssFee` + `creatorFee` + `ownerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @param buyer The address of the collector that purchased the NFT using `buy`.
   * @param seller The address of the seller which originally set the buy price.
   * @param mssFee The amount of ETH that was sent to market for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param ownerRev The amount of ETH that was sent to the owner for this sale.
   */
  event FixedPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenID,
    address indexed seller,
    address buyer,
    uint256 mssFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  /**
   * @notice Emitted when the buy price is removed by the owner of an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   */
  event FixedPriceCanceled(address indexed nftContract, uint256 indexed tokenID, string reason);
  /**
   * @notice Emitted when a buy price is set by the owner of an NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @param seller The address of the NFT owner which set the buy price.
   * @param price The price of the NFT.
   */
  event FixedPriceSet(address indexed nftContract, uint256 indexed tokenID, address indexed seller, uint256 price);
  /**
  * @notice Fixed price updated.
  * @param nftContract The address of the NFT contract.
  * @param tokenID The id of the NFT.
  * @param beforAmount The previous price of the NFT.
  * @param afterAmount The new price of the NFT.
  */
  event FixedPriceUpdated(address indexed nftContract, uint256 indexed tokenID, uint256 beforAmount, uint256 afterAmount);

  /**
   * @notice Buy the NFT at the set buy price.
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   */
  function buy(address nftContract, uint256 tokenID) external payable {
    FixedPrice storage fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];
    
    require(fixedPrice.price <= msg.value, "MarketFixedPrice: Cannot buy at lower price");
    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot buy unset price");
    require(fixedPrice.seller != msg.sender, "MarketFixedPrice: Cannot buy own FixedPrice");
   
    _buy(nftContract, tokenID);
  }
  /**
   * @notice Removes the buy price set for an NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   */
  function adminCancelFixedPrice(address nftContract, uint256 tokenID, string calldata reason) external onlyAdmin {
    FixedPrice storage fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];

    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot cancel unset price"); // This check is redundant with the next one, but done in order to provide a more clear error message.
    // Remove the buy price
    delete nftContractToTokenIDToFixedPrice[nftContract][tokenID];
  
    emit FixedPriceCanceled(nftContract, tokenID, reason);
  }
  /**
   * @notice Sets the buy price for an NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @param price The price at which someone could buy this NFT.
   */
  function createFixedPrice(address nftContract, uint256 tokenID, address seller, uint256 price, uint16 marketFee) external onlyAdmin {
    require(price <= type(uint96).max, "MarketFixedPrice: Price too high"); // This ensures that no data is lost when storing the price as `uint96`.
    require(!_getNFTContractToTokenIDFirstSale(nftContract, tokenID), "MarketFixedPrice: NFTs first sold");

    if (MIN_MARKET_FEE_BASIS_POINTS > marketFee || marketFee > MAX_MARKET_FEE_BASIS_POINTS) {
      revert(ERROR_MARKET_FIXED_PRICE_ARGUMENTS);
    }
    
    _checkActiveMarket(nftContract, tokenID);

    FixedPrice storage fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];

    require(fixedPrice.seller == address(0), "MarketFixedPrice: Cannot set price twice");
    // 이 컨트랙트가 소유자인지 확인하고 소유자가 아니면 에러
    require(address(this) == _getInterfacesOwnerOf(nftContract, tokenID), "MarketFixedPrice: Only NFT contract owner can create auction");

    // 원작자 확인 NFTContract.TokenCreator(uint256 tokenID)
    address tokenCreator = _getInterfacesTokenCreator(nftContract, tokenID);
    if (tokenCreator != address(0)) {
      require(tokenCreator == seller, "MarketFixedPrice: Only token creator can create auction");
    }

    // Store the new price for this NFT.
    fixedPrice.price = uint96(price);
    fixedPrice.seller = payable(seller);
    fixedPrice.marketFee = marketFee;

    emit FixedPriceSet(nftContract, tokenID, msg.sender, price);
  }
  /**
   * @notice 등록된 NFT 가격을 변경합니다.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @param price The price at which someone could buy this NFT.
   */
  function updateFixedPrice(address nftContract, uint256 tokenID, uint256 price) external onlyAdmin {
    FixedPrice storage fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];

    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot cancel unset price"); // This check is redundant with the next one, but done in order to provide a more clear error message.
    require(price <= type(uint96).max, "MarketFixedPrice: Price too high"); // This ensures that no data is lost when storing the price as `uint96`.
    require(fixedPrice.price != price, "MarketFixedPrice: Cannot update price to same value");

    uint96 beforAmount = fixedPrice.price;
    fixedPrice.price = uint96(price);

    emit FixedPriceUpdated(nftContract, tokenID, beforAmount, fixedPrice.price);
  }
  /**
   * @notice Process the purchase of an NFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(address nftContract, uint256 tokenID) private nonReentrant {
    FixedPrice memory fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];
    // Remove the buy now price
    delete nftContractToTokenIDToFixedPrice[nftContract][tokenID];

    if (fixedPrice.price < msg.value) {
      // Return any surplus funds to the buyer.
      unchecked {
        // The if above ensures this will not underflow
        payable(msg.sender).sendValue(msg.value - fixedPrice.price);
      }
    }

    // Transfer the NFT to the buyer.
    // This should revert if the `msg.sender` is not the owner of this NFT.
    _transferFromMarket(nftContract, tokenID, msg.sender);

    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(address(nftContract), tokenID, fixedPrice.seller, fixedPrice.price, fixedPrice.marketFee);

    emit FixedPriceAccepted(nftContract, tokenID, fixedPrice.seller, msg.sender, mssFee, creatorFee, ownerRev);
  }

  /**
  * @inheritdoc MarketCore
  * @dev If it is checked whether it is registered in another sales method, it will be invalidated.
  */
  function _checkActiveMarket(address nftContract, uint256 tokenID) internal virtual override {
    FixedPrice storage fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];
    require(fixedPrice.seller == address(0), "MarketFixedPrice: Active buy now");
    super._checkActiveMarket(nftContract, tokenID);
  }  
  /**
   * @notice Returns the buy price details for an NFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @return seller The address of the owner that listed a buy price for this NFT.
   * Returns `address(0)` if there is no buy price set for this NFT.
   * @return price The price of the NFT.
   * Returns `0` if there is no buy price set for this NFT.
   */
  function getFixedPrice(address nftContract, uint256 tokenID) external view returns (address seller, uint256 price) {
    FixedPrice storage fixedPrice = nftContractToTokenIDToFixedPrice[nftContract][tokenID];
    if (fixedPrice.seller == address(0)) {
      return (address(0), type(uint256).max);
    }
    return (fixedPrice.seller, fixedPrice.price);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Constant values shared across mixins.
 */
abstract contract Constants {
  /**
   * @notice 100% in basis points.
   */
  uint256 internal constant BASIS_POINTS = 10000;

  /**
   * @notice The minimum increase of 10% required when making an offer or placing a bid.
   */
  uint256 internal constant MIN_PERCENT_INCREMENT_IN_BASIS_POINTS = 1000;

  /**
   * @notice The gas limit used when making external read-only calls.
   * @dev This helps to ensure that external calls does not prevent the market from executing.
   */
  uint256 internal constant READ_ONLY_GAS_LIMIT = 40000;

  /**
   * @notice The gas limit to send ETH to multiple recipients, enough for a 5-way split.
   */
  uint256 internal constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

  /**
   * @notice The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
   */
  uint256 internal constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 internal constant EXTENSION_DURATION = 10 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 internal constant MAX_MAX_DURATION = 1000 days;
  
  /// @notice 마켓 수수료 최소 값
  uint256 internal constant MIN_MARKET_FEE_BASIS_POINTS = 100; // 1%
  
  /// @notice 마켓 수수료 최대 값
  uint256 internal constant MAX_MARKET_FEE_BASIS_POINTS = 5000; // 50%

  /// @notice Error message constant
  // Market auction
  string internal constant ERROR_MARKET_AUCTION_ARGUMENTS = "MarketAuction : Invalid argument value.";
  string internal constant ERROR_MARKET_AUCTION_NO_REGISTERED = "MarketAuction : There are no auctions registered.";

  // Market Fixed Price
  string internal constant ERROR_MARKET_FIXED_PRICE_ARGUMENTS = "MarketFixedPrice : Invalid argument value.";
  string internal constant ERROR_MARKET_FIXED_PRICE_NO_REGISTERED = "MarketFixedPrice : There are no fixed price registered.";

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Admin.sol";
import "./Constants.sol";
import "./MarketCore.sol";
import "./SupportsInterfaces.sol";
import "./SendValueWithFallbackWithdraw.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title A mixin to distribute funds when an NFT is sold.
 */
abstract contract MarketFees is Constants, Initializable, Admin, MarketCore, SupportsInterfaces, SendValueWithFallbackWithdraw {
  using AddressUpgradeable for address payable;
  /**
   * @notice Distributes funds to market, creator recipients, and NFT owner after a sale.
   */
  // solhint-disable-next-line code-complexity
  function _distributeFunds(address nftContract, uint256 tokenID, address payable seller, uint256 price, uint16 sendMarketFee) internal returns (uint256 marketFee, uint256 creatorFee, uint256 ownerRev)
  {
    address payable creatorRecipient;

    address payable ownerRevTo;
    (marketFee, creatorRecipient, creatorFee, ownerRevTo, ownerRev) = _getFees(nftContract, tokenID, seller, price, sendMarketFee);

    _sendValueWithFallbackWithdraw(treasury, marketFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    if (creatorFee > 0 && creatorRecipient != address(0)) {
      _sendValueWithFallbackWithdraw(creatorRecipient, creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
    } else {
      // IRoyaltyInfo로 지급 받을 주소가 없으면 판매자 지갑으로 지급
      _sendValueWithFallbackWithdraw(ownerRevTo, ownerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }
    _setNFTContractToTokenIDFirstSale(nftContract, tokenID);
  }
  /**
   * @dev Calculates how funds should be distributed for the given sale details.
   */
  function _getFees(address nftContract, uint256 tokenId, address payable seller, uint256 price, uint16 sendMarketFee) private view
    returns (uint256 marketFee, address payable creatorRecipient, uint256 creatorRev, address payable ownerRevTo, uint256 ownerRev) {
    
    // 판매자에게 지급될 금액을 로열티주소에서 가져오기
    // 첫 판매는 원작자가 판매
    creatorRecipient = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    
    // Calculate the market fee
    marketFee = (price * sendMarketFee) / BASIS_POINTS;

    if (creatorRecipient != address(0)) {
      // When sold by the creator, all revenue is split if applicable.
      creatorRev = price - marketFee;
    } else {
      // No royalty recipients found.
      ownerRevTo = seller;
      ownerRev = price - marketFee;
    }
  }
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../Libraries/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";

import "../Interfaces/IRoyaltyInfo.sol";
import "../Interfaces/ITokenCreator.sol";

/**
 * @title A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract SupportsInterfaces is Constants, ReentrancyGuardUpgradeable { // Adding this unused mixin to help with linearization 
  using ERC165Checker for address;

  /**
   * @notice Looks up the royalty payment configuration for a given NFT.
   */
  // solhint-disable-next-line code-complexity
  function _getInterfacesCreatorPaymentInfo(address nftContract, uint256 tokenID) internal view returns (address payable recipient) {
    // 1st priority: ERC-2981
    if (nftContract.supportsERC165Interface(type(IRoyaltyInfo).interfaceId)) {
      (address receiver, ) = IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenID, BASIS_POINTS);
      if (receiver != address(0)) {
        recipient = payable(receiver);
      } else {
        recipient = payable(0);
      }
    }
    return recipient;
  }

  /**
   * @notice NFT 창작자를 찾는다 없으면.....
   */
  function _getInterfacesTokenCreator(address nftContract, uint256 tokenID) internal view returns (address tokenCreator) {
    if(nftContract.supportsERC165Interface(type(ITokenCreator).interfaceId)) {
      tokenCreator = ITokenCreator(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenID);
    } else {
      tokenCreator = address(0);
    }
    return tokenCreator;
  }

  /**
   * @notice NFT Owner를 찾는다 없으면.....
   */
  function _getInterfacesOwnerOf(address nftContract, uint256 tokenID) internal view returns (address tokenOwner) {
    tokenOwner = IERC721Upgradeable(nftContract).ownerOf(tokenID);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol
 * Modified to allow checking multiple interfaces w/o checking general 165 support.
 */

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @title Library to query ERC165 support.
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
  // As per the EIP-165 spec, no interface should ever match 0xffffffff
  bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

  /**
   * @dev Returns true if `account` supports the {IERC165} interface,
   */
  function supportsERC165(address account) internal view returns (bool) {
    // Any contract that implements ERC165 must explicitly indicate support of
    // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
    return supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) && !supportsERC165Interface(account, _INTERFACE_ID_INVALID);
  }

  /**
   * @dev Returns true if `account` supports the interface defined by
   * `interfaceId`. Support for {IERC165} itself is queried automatically.
   *
   * See {IERC165-supportsInterface}.
   */
  function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
    // query support of both ERC165 as per the spec and support of _interfaceId
    return supportsERC165(account) && supportsERC165Interface(account, interfaceId);
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
  function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
    // an array of booleans corresponding to interfaceIds and whether they're supported or not
    bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

    // query support of ERC165 itself
    if (supportsERC165(account)) {
      // query support of each interface in interfaceIds
      unchecked {
        for (uint256 i = 0; i < interfaceIds.length; ++i) {
          interfaceIdsSupported[i] = supportsERC165Interface(account, interfaceIds[i]);
        }
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
    unchecked {
      for (uint256 i = 0; i < interfaceIds.length; ++i) {
        if (!supportsERC165Interface(account, interfaceIds[i])) {
          return false;
        }
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
  function supportsERC165Interface(address account, bytes4 interfaceId) internal view returns (bool) {
    bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable(account).supportsInterface.selector, interfaceId);
    (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for EIP-2981: NFT Royalty Standard.
 * For more see: https://eips.ethereum.org/EIPS/eip-2981.
 */
interface IRoyaltyInfo {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for EIP-2981: NFT Royalty Standard.
 * For more see: https://eips.ethereum.org/EIPS/eip-2981.
 */
interface ITokenCreator {
  /// @notice 해당 토큰에 제작자 주소를 조회
  /// @param tokenID - NFT Token ID
  /// @return creator - 해당 토큰에 제작자 주소
  function tokenCreator(uint256 tokenID) external view returns (address creator);
}