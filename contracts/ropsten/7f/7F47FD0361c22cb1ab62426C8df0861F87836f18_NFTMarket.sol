// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Utils/MarketCore.sol";
import "./Utils/MarketRoyalty.sol";
import "./Utils/MarketFees.sol";
import "./Utils/SendValueWithFallbackWithdraw.sol";

import "./Market/Auction.sol";

/**
 * @title Aution Market Test Contract
 * @notice Notice Foundation 마켓 모델
 * @dev 주석 주석
 */
contract NFTMarket is Initializable, MarketCore, ReentrancyGuardUpgradeable, MarketRoyalty, SendValueWithFallbackWithdraw, MarketFees, MarketAuction {
   /**
    * @notice Set immutable variables for the implementation contract.
    * @dev Using immutable instead of constants allows us to use different values on testnet.
    */
  constructor(address payable _treasury, uint256 _duration) MarketFees(_treasury) MarketAuction(_duration) {}

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
   */
  function initialize() external initializer {
    MarketAuction._initializeAuctionID();
  }
  /**
   * @inheritdoc MarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferFromEscrow(address nftContract, uint256 tokenID, address recipient, address seller) internal override(MarketCore, MarketAuction){
    super._transferFromEscrow(nftContract, tokenID, recipient, seller);
  }

  /**
   * @inheritdoc MarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenID, address recipient) internal override(MarketCore, MarketAuction) {
    super._transferFromEscrowIfAvailable(nftContract, tokenID, recipient);
  }

  /**
   * @inheritdoc MarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferToEscrow(address nftContract, uint256 tokenID) internal override(MarketCore, MarketAuction) {
    super._transferToEscrow(nftContract, tokenID);
  }

  /**
   * @inheritdoc MarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenID) internal view override(MarketCore, MarketAuction) returns (address payable seller) {
    return super._getSellerFor(nftContract, tokenID);
  }
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

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./Constants.sol";

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract MarketCore is Constants {
  using AddressUpgradeable for address;

  /**
   * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
   */
  function _transferFromEscrow(address nftContract, uint256 tokenID, address recipient, address /*seller*/) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenID);
  }

  /**
   * @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenID, address recipient) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenID);
  }

  /**
   * @notice Transfers an NFT into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this NFT.
   */
  function _transferToEscrow(address nftContract, uint256 tokenID) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenID);
  }

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
   * @notice Checks who the seller for an NFT is, checking escrow or return the current owner if not in escrow.
   * @dev If the NFT did not have an escrowed seller to return, fall back to return the current owner.
   */
  function _getSellerFor(address nftContract, uint256 tokenID) internal view virtual returns (address payable seller) {
    seller = payable(IERC721Upgradeable(nftContract).ownerOf(tokenID));
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 50 slots were consumed by adding `ReentrancyGuard`.
   */
  uint256[950] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../Libraries/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";

import "../Interfaces/IRoyaltyInfo.sol";

/**
 * @title A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract MarketRoyalty is Constants, ReentrancyGuardUpgradeable { // Adding this unused mixin to help with linearization 
  using ERC165Checker for address;

  /**
   * @notice Looks up the royalty payment configuration for a given NFT.
   * @dev This will check various royalty APIs on the NFT and the royalty override
   * if one was registered with the royalty registry. This aims to send royalties
   * in the manner requested by the NFT owner, regardless of where the NFT was minted.
   */
  // solhint-disable-next-line code-complexity
  function _getCreatorPaymentInfo(address nftContract, uint256 tokenId, address seller) internal view returns (
      address payable[] memory recipients, uint256[] memory splitPerRecipientInBasisPoints, bool isCreator)
  {
    // All NFTs implement 165 so we skip that check, individual interfaces should return false if 165 is not implemented

    // 1st priority: ERC-2981
    if (nftContract.supportsERC165Interface(type(IRoyaltyInfo).interfaceId)) {
      try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
        address receiver,
        uint256 /* royaltyAmount */
      ) {
        if (receiver != address(0)) {
          recipients = new address payable[](1);
          recipients[0] = payable(receiver);
          // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
          if (receiver == seller) {
            return (recipients, splitPerRecipientInBasisPoints, true);
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }
    // If no valid payment address or creator is found, return 0 recipients
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 500 slots were consumed with the addition of `SendValueWithFallbackWithdraw`.
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Constants.sol";
import "./MarketCore.sol";
import "./MarketRoyalty.sol";
import "./SendValueWithFallbackWithdraw.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title A mixin to distribute funds when an NFT is sold.
 */
abstract contract MarketFees is Constants, Initializable, MarketCore, MarketRoyalty, SendValueWithFallbackWithdraw {
  using AddressUpgradeable for address payable;

  /// @notice Track if there has been a sale for the NFT in this market previously.
  mapping(address => mapping(uint256 => bool)) private _nftContractToTokenIdToFirstSaleCompleted;

  /// @notice The address of the treasury contract.
  address payable public treasury;

  constructor(address payable _treasury) {
        require(!_treasury.isContract(), "MarketFees: Treasury address is a contract");

        treasury = _treasury;
  }

  /**
   * @notice Distributes funds to foundation, creator recipients, and NFT owner after a sale.
   */
  // solhint-disable-next-line code-complexity
  function _distributeFunds(address nftContract, uint256 tokenId, address payable seller, uint256 price) internal returns (uint256 foundationFee, uint256 creatorFee, uint256 ownerRev)
  {
    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;

    address payable ownerRevTo;
    (foundationFee, creatorRecipients, creatorShares, creatorFee, ownerRevTo, ownerRev) = _getFees(
      nftContract,
      tokenId,
      seller,
      price
    );

    _sendValueWithFallbackWithdraw(treasury, foundationFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    if (creatorFee > 0) {
      if (creatorRecipients.length > 1) {
        uint256 maxCreatorIndex = creatorRecipients.length - 1;
        if (maxCreatorIndex > MAX_ROYALTY_RECIPIENTS_INDEX) {
          maxCreatorIndex = MAX_ROYALTY_RECIPIENTS_INDEX;
        }

        // Determine the total shares defined so it can be leveraged to distribute below
        uint256 totalShares;
        unchecked {
          // The array length cannot overflow 256 bits.
          for (uint256 i = 0; i <= maxCreatorIndex; ++i) {
            if (creatorShares[i] > BASIS_POINTS) {
              // If the numbers are >100% we ignore the fee recipients and pay just the first instead
              maxCreatorIndex = 0;
              break;
            }
            // The check above ensures totalShares wont overflow.
            totalShares += creatorShares[i];
          }
        }
        if (totalShares == 0) {
          maxCreatorIndex = 0;
        }

        // Send payouts to each additional recipient if more than 1 was defined
        uint256 totalDistributed;
        for (uint256 i = 1; i <= maxCreatorIndex; ++i) {
          uint256 share = (creatorFee * creatorShares[i]) / totalShares;
          totalDistributed += share;
          _sendValueWithFallbackWithdraw(creatorRecipients[i], share, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
        }

        // Send the remainder to the 1st creator, rounding in their favor
        _sendValueWithFallbackWithdraw(
          creatorRecipients[0],
          creatorFee - totalDistributed,
          SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS
        );
      } else {
        _sendValueWithFallbackWithdraw(creatorRecipients[0], creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
      }
    }
    _sendValueWithFallbackWithdraw(ownerRevTo, ownerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    _nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;
  }

  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The sale price to calculate the fees for.
   * @return foundationFee How much will be sent to the Foundation treasury.
   * @return creatorRev How much will be sent across all the `creatorRecipients` defined.
   * @return creatorRecipients The addresses of the recipients to receive a portion of the creator fee.
   * @return creatorShares The percentage of the creator fee to be distributed to each `creatorRecipient`.
   * If there is only one `creatorRecipient`, this may be an empty array.
   * Otherwise `creatorShares.length` == `creatorRecipients.length`.
   * @return ownerRev How much will be sent to the owner/seller of the NFT.
   * If the NFT is being sold by the creator, this may be 0 and the full revenue will appear as `creatorRev`.
   * @return owner The address of the owner of the NFT.
   * If `ownerRev` is 0, this may be `address(0)`.
   */
  function getFeesAndRecipients(address nftContract, uint256 tokenId, uint256 price) external view
    returns (
      uint256 foundationFee,
      uint256 creatorRev,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 ownerRev,
      address payable owner
    )
  {
    address payable seller = _getSellerFor(nftContract, tokenId);
    (foundationFee, creatorRecipients, creatorShares, creatorRev, owner, ownerRev) = _getFees(
      nftContract,
      tokenId,
      seller,
      price
    );
  }

  /**
   * @dev Calculates how funds should be distributed for the given sale details.
   */
  function _getFees(address nftContract, uint256 tokenId, address payable seller, uint256 price) private view
    returns (
      uint256 foundationFee,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 creatorRev,
      address payable ownerRevTo,
      uint256 ownerRev
    )
  {
    bool isCreator;
    (creatorRecipients, creatorShares, isCreator) = _getCreatorPaymentInfo(nftContract, tokenId, seller); // 로열티를 비율로 가져옴(ERC2981 인터페이스 이용) 하지만 해당 비율은 사용하지 않는듯
    // 파운데이션 자체 비율을 사용하며 위에 10%로 고정되어 있음 여기서 로열티에 대한 정보를 얻지 못하면 로열티 지급은 안함
    // Calculate the Foundation fee
    uint256 fee;
    if (isCreator && !_nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId]) {
      fee = PRIMARY_FOUNDATION_FEE_BASIS_POINTS;
    } else {
      fee = SECONDARY_FOUNDATION_FEE_BASIS_POINTS;
    }

    foundationFee = (price * fee) / BASIS_POINTS;

    if (creatorRecipients.length > 0) {
      if (isCreator) {
        // When sold by the creator, all revenue is split if applicable.
        creatorRev = price - foundationFee;
      } else {
        // Rounding favors the owner first, then creator, and foundation last.
        creatorRev = (price * CREATOR_ROYALTY_BASIS_POINTS) / BASIS_POINTS;
        ownerRevTo = seller;
        ownerRev = price - foundationFee - creatorRev;
      }
    } else {
      // No royalty recipients found.
      ownerRevTo = seller;
      ownerRev = price - foundationFee;
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../Utils/MarketCore.sol";
import "../Utils/MarketRoyalty.sol";
import "../Utils/MarketFees.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";

abstract contract MarketAuction is Initializable, MarketCore, ReentrancyGuardUpgradeable, MarketRoyalty, SendValueWithFallbackWithdraw, MarketFees {
  using AddressUpgradeable for address payable;
  /// @notice Stores the auction configuration for a specific NFT.
  struct AuctionData {
      /// @notice The address of the NFT contract.
      address nftContract;
      /// @notice The id of the NFT.
      uint256 tokenID;
      /// @notice The owner of the NFT which listed it in auction.
      address payable seller;
      /// @notice The duration for this auction.
      uint256 duration;
      /// @notice The extension window for this auction.
      uint256 extensionDuration;
      /// @notice 경매 시작 시간 Unix timestamp 형태로 저장. 0이면 사용 안함
      /// @dev 예외 처리로 생각해 볼게 많음 유저가 옥션을 만든다고 하면 유저가 보낸 이 값을 어떻게 보장하지...?
      uint256 startTime;
      /// @notice The time at which this auction will not accept any new bids.
      /// @dev This is `0` until the first bid is placed.
      uint256 endTime;
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
  /// @notice How long an auction lasts for once the first bid has been received.
  uint256 public DURATION;
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
  * @param nftContract The address of the NFT contract.
  * @param tokenID The id of the NFT.
  * @param duration The duration of the auction (always 24-hours).
  * @param extensionDuration The duration of the auction extension window (always 15-minutes).
  * @param reservePrice The reserve price to kick off the auction.
  * @param auctionID The id of the auction that was created.
  */
  event AuctionCreated(address indexed seller, address indexed nftContract, uint256 indexed tokenID, uint256 duration, uint256 extensionDuration, uint256 startTime, uint256 reservePrice, uint256 auctionID);
 /**
  * @notice Emitted when an auction that has already ended is finalized,
  * indicating that the NFT has been transferred and revenue from the sale distributed.
  * @dev The amount of the highest bid / final sale price for this auction is `f8nFee` + `creatorFee` + `ownerRev`.
  * @param auctionID The id of the auction that was finalized.
  * @param seller The address of the seller.
  * @param bidder The address of the highest bidder that won the NFT.
  * @param f8nFee The amount of ETH that was sent to Foundation for this sale.
  * @param creatorFee The amount of ETH that was sent to the creator for this sale.
  * @param ownerRev The amount of ETH that was sent to the owner for this sale.
  */
  event AuctionFinalized(uint256 indexed auctionID, address indexed seller, address indexed bidder, uint256 f8nFee, uint256 creatorFee, uint256 ownerRev);
 /**
  * @notice Emitted when an auction is invalidated due to other market activity.
  * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
  * @param auctionID The id of the auction that was invalidated.
  */
  event AuctionInvalidated(uint256 indexed auctionID);
 /**
  * @notice Set immutable variables for the implementation contract.
  * @dev Using immutable instead of constants allows us to use different values on testnet.
  */
  constructor(uint256 _duration) {
      require(_duration <= MAX_MAX_DURATION, "MarketAuction: Exceeds Max Duration"); // This ensures that math in this file will not overflow due to a huge duration.
      require(_duration >= EXTENSION_DURATION, "MarketAuction: Less Than Extension Duration"); // The auction duration configuration must be greater than the extension window of 15 minutes
    
      DURATION = _duration;
  }

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This sets the initial auction id to 1, making the first auction cheaper
   * and id 0 represents no auction found.
   */
  function _initializeAuctionID() internal onlyInitializing {
    nextAuctionID = 1;
  }

  /**
   * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to
   * the seller (if not active buy price set).
   * This should only be used for extreme cases such as DMCA takedown requests.
   * @param auctionID The id of the auction to cancel.
   * @param reason The reason for the cancellation (a required field).
   */
  function adminCancelAuction(uint256 auctionID, string calldata reason) external nonReentrant { // onlyFoundationAdmin

    require(bytes(reason).length != 0, "MarketAuction: Cannot Admin Cancel Without Reason");
    AuctionData memory auction = auctionIDToAuction[auctionID];

    require(auction.amount != 0, "MarketAuction: Cannot Cancel Nonexistent Auction");
    
    delete nftContractTokenIDToAuctionID[auction.nftContract][auction.tokenID];
    delete auctionIDToAuction[auctionID];

    // Return the NFT to the owner.
    _transferFromEscrowIfAvailable(auction.nftContract, auction.tokenID, auction.seller);

    if (auction.bidder != address(0)) {
      // Refund the highest bidder if any bids were placed in this auction.
      _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionCanceled(auctionID, reason);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   * @param nftContract The address of the NFT contract.
   * @param tokenID The id of the NFT.
   * @param auctionPrice The initial reserve price for the auction.
   */
  function createAuction(address nftContract, uint256 tokenID, uint256 auctionPrice, uint256 startUnixTime) external nonReentrant {
      require(auctionPrice != 0, "MarketAuction: Price Must Be Greater Than 0");
      uint256 auctionID = _getNextAndIncrementAuctionID();
      // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
      _transferToEscrow(nftContract, tokenID);
      // Store the auction details
      nftContractTokenIDToAuctionID[nftContract][tokenID] = auctionID;
      auctionIDToAuction[auctionID] = AuctionData(
      nftContract,
      tokenID,
      payable(msg.sender),
      DURATION,
      EXTENSION_DURATION,
      startUnixTime,
      0, // endTime is only known once the reserve price is met
      payable(0), // bidder is only known once a bid has been placed
      auctionPrice
      );
      emit AuctionCreated(msg.sender, nftContract, tokenID, DURATION, EXTENSION_DURATION, startUnixTime, auctionPrice, auctionID);
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
      require(auction.amount != 0, "MarketAuction: Cannot Bid On Nonexistent Auction");  // No auction found
      require(auction.startTime <= block.timestamp, "MarketAuction: Cannot Bid Before Auction Starts"); // Auction hasn't started yet

      if (auction.endTime == 0) {
        // This is the first bid, kicking off the auction.
        require(auction.amount <= msg.value, "MarketAuction: Cannot Bid Lower Than Reserve Price"); // The bid must be >= the reserve price.
 
        // Store the bid details.
        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);
        // On the first bid, set the endTime to now + duration.
        unchecked {
          // Duration is always set to 24hrs so the below can't overflow.
          auction.endTime = block.timestamp + auction.duration;
        }
      } else {
          require(auction.endTime >= block.timestamp, "MarketAuction: Cannot Bid On Ended Auction"); // The auction has already ended.{
          require(auction.bidder != msg.sender, "MarketAuction: Cannot Rebid Over Outstanding Bid"); // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
          require(msg.value >= _getMinIncrement(auction.amount), "MarketAuction: Bid Must Be At Least Min Amount"); // If this bid outbids another, it must be at least 10% greater than the last bid.
          // Cache and update bidder state
          uint256 originalAmount = auction.amount;
          address payable originalBidder = auction.bidder;
          auction.amount = msg.value;
          auction.bidder = payable(msg.sender);
          unchecked {
            // When a bid outbids another, check to see if a time extension should apply.
            // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
            if (auction.endTime - block.timestamp < auction.extensionDuration) {
              // Current time plus extension duration (always 15 mins) cannot overflow.
              auction.endTime = block.timestamp + auction.extensionDuration;
            }
          }
          // Refund the previous bidder
          _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
      }
      emit AuctionBidPlaced(auctionID, msg.sender, msg.value, auction.endTime);
  }
  /**
  * @notice Once the countdown has expired for an auction, anyone can settle the auction.
  * This will send the NFT to the highest bidder and distribute revenue for this sale.
  * @param auctionID The id of the auction to settle.
  */
  function finalizeAuction(uint256 auctionID) external nonReentrant {
      require(auctionIDToAuction[auctionID].endTime != 0, "MarketAuction: Cannot Finalize Already Settled Auction");
      _finalizeAuction(auctionID, false);
  }
  /**
  * @notice Settle an auction that has already ended.
  * This will send the NFT to the highest bidder and distribute revenue for this sale.
  * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
  * redundant transfers if the NFT should remain in escrow, such as when the new owner
  * sets a buy price or lists it in a new auction.
  */
  function _finalizeAuction(uint256 auctionID, bool keepInEscrow) private {
      AuctionData memory auction = auctionIDToAuction[auctionID];
      require(auction.endTime < block.timestamp, "MarketAuction: Cannot Finalize Auction In Progress");
      // Remove the auction.
      delete nftContractTokenIDToAuctionID[auction.nftContract][auction.tokenID];
      delete auctionIDToAuction[auctionID];
      if (!keepInEscrow) {
        /*
         * Save gas by calling core directly since it cannot have another escrow requirement
         * (buy price set or another auction listed) until this one has been finalized.
         */
        MarketCore._transferFromEscrow(auction.nftContract, auction.tokenID, auction.bidder, address(0));
      }
      // Distribute revenue for this sale.
      (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(auction.nftContract, auction.tokenID, auction.seller, auction.amount);
      emit AuctionFinalized(auctionID, auction.seller, auction.bidder, f8nFee, creatorFee, ownerRev);
  }
  /**
 * @inheritdoc MarketCore
 * @dev If an auction is found:
 *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
 *  - If the auction has not received a bid, it will invalidate the auction.
 *  - If the auction is in progress, this will revert.
 */
function _transferFromEscrow(address nftContract, uint256 tokenID, address recipient, address seller) internal virtual override {
      uint256 auctionID = nftContractTokenIDToAuctionID[nftContract][tokenID];
      if (auctionID != 0) {
        AuctionData storage auction = auctionIDToAuction[auctionID];
        if (auction.endTime == 0) {
          // The auction has not received any bids yet so it may be invalided.
          require (auction.seller == seller, "MarketAuction: Not Matching Seller");
          // Remove the auction.
          delete nftContractTokenIDToAuctionID[nftContract][tokenID];
          delete auctionIDToAuction[auctionID];
          emit AuctionInvalidated(auctionID);
        } else {
          // If the auction has started, the highest bidder will be the new owner.
          require (auction.bidder == seller, "MarketAuction: Not Matching Seller");
          // Finalization will revert if the auction has not yet ended.
          _finalizeAuction(auctionID, false);
          // Finalize includes the transfer, so we are done here.
          return;
        }
      }
      super._transferFromEscrow(nftContract, tokenID, recipient, seller);
  }

  /**
   * @inheritdoc MarketCore
   * @dev Checks if there is an auction for this NFT before allowing the transfer to continue.
   */
  function _transferFromEscrowIfAvailable(address nftContract, uint256 tokenID, address recipient) internal virtual override {
    if (nftContractTokenIDToAuctionID[nftContract][tokenID] == 0) {
      // No auction was found

      super._transferFromEscrowIfAvailable(nftContract, tokenID, recipient);
    }
  }
  
  /**
  * @inheritdoc MarketCore
  */
  function _transferToEscrow(address nftContract, uint256 tokenID) internal virtual override {
      uint256 auctionID = nftContractTokenIDToAuctionID[nftContract][tokenID];
      if (auctionID == 0) {
        // NFT is not in auction
        super._transferToEscrow(nftContract, tokenID);
        return;
      }
      // Using storage saves gas since most of the data is not needed
      AuctionData storage auction = auctionIDToAuction[auctionID];
      if (auction.endTime == 0) {
        // Reserve price set, confirm the seller is a match
        require(auction.seller == msg.sender, "MarketAuction: Not Matching Seller");
      } else {
        // Auction in progress, confirm the highest bidder is a match
        require(auction.bidder == msg.sender, "MarketAuction: Not Matching Seller");
        // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
        _finalizeAuction(auctionID, true);
      }
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
   * @notice Returns auction details for a given auctionId.
   * @param auctionID The id of the auction to lookup.
   * @return auction The auction details.
   */
  function getAuctionData(uint256 auctionID) external view returns (AuctionData memory auction) {
    return auctionIDToAuction[auctionID];
  }
  /**
   * @notice 주어진 경매 ID에 경매 시작 시간을 리턴 합니다.
   * @param auctionID The id of the auction to lookup.
   * @return startUnixTime UnixTimestamp 형태로 리턴 0일경우 시간 설정 하지 않음
   */
  function getAuctionStartTime(uint256 auctionID) external view returns (uint256 startUnixTime) {
    return auctionIDToAuction[auctionID].startTime;
  }
/**
  * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
  * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
  * @param nftContract The address of the NFT contract.
  * @param tokenID The id of the NFT.
  * @return auctionID The id of the auction, or 0 if no auction is found.
  */
  function getAuctionIDFor(address nftContract, uint256 tokenID) external view returns (uint256 auctionID) {
    return nftContractTokenIDToAuctionID[nftContract][tokenID];
  }

  /**
   * @inheritdoc MarketCore
   * @dev Returns the seller that has the given NFT in escrow for an auction,
   * or bubbles the call up for other considerations.
   */
  function _getSellerFor(address nftContract, uint256 tokenID) internal view virtual override returns (address payable seller) {
    seller = auctionIDToAuction[nftContractTokenIDToAuctionID[nftContract][tokenID]].seller;
    if (seller == address(0)) {
      seller = super._getSellerFor(nftContract, tokenID);
    }
  }

/**
  * @notice Applies only to auctions created after the Duration Value setting is applied.
  * @param _duration Input in seconds You can input from a minimum of 15 minutes to a maximum of 1000 days
  */
  function setDuration (uint256 _duration) external {
      require(_duration <= MAX_MAX_DURATION, "MarketAuction: Exceeds Max Duration"); // This ensures that math in this file will not overflow due to a huge duration.
      require(_duration >= EXTENSION_DURATION, "MarketAuction: Less Than Extension Duration"); // The auction duration configuration must be greater than the extension window of 15 minutes
    
      DURATION = _duration;
  }

  /**
   * @notice Returns id to assign to the next auction.
   */
  function _getNextAndIncrementAuctionID() internal returns (uint256) {
    // AuctionId cannot overflow 256 bits.
    unchecked {
      return nextAuctionID++;
    }
  }
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
   * @notice Cap the number of royalty recipients to 5.
   * @dev A cap is required to ensure gas costs are not too high when a sale is settled.
   */
  uint256 internal constant MAX_ROYALTY_RECIPIENTS_INDEX = 4;

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
  uint256 internal constant EXTENSION_DURATION = 15 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 internal constant MAX_MAX_DURATION = 1000 days;

    /// @notice The royalties sent to creator recipients on secondary sales.
  uint256 internal constant CREATOR_ROYALTY_BASIS_POINTS = 1000; // 10%
  /// @notice The fee collected by Foundation for sales facilitated by this market contract for a primary sale.
  uint256 internal constant PRIMARY_FOUNDATION_FEE_BASIS_POINTS = 1500; // 15%
  /// @notice The fee collected by Foundation for sales facilitated by this market contract for a secondary sale.
  uint256 internal constant SECONDARY_FOUNDATION_FEE_BASIS_POINTS = 500; // 5%
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
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}