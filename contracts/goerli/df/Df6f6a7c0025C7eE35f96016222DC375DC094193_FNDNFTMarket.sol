/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/FoundationTreasuryNode.sol";
import "./mixins/roles/FoundationAdminRole.sol";
import "./mixins/roles/FoundationOperatorRole.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";
import "./mixins/NFTMarketCreators.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "./mixins/NFTMarketPrivateSale.sol";
import "./mixins/NFTMarketBuyNow.sol";
import "./mixins/NFTMarketOffer.sol";

/**
 * @title A market for NFTs on Foundation.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract FNDNFTMarket is
  FoundationTreasuryNode,
  FoundationAdminRole,
  FoundationOperatorRole,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction,
  NFTMarketPrivateSale,
  NFTMarketBuyNow,
  NFTMarketOffer
{
  constructor(
    address payable treasury,
    address feth,
    address royaltyRegistry,
    uint256 duration,
    address proxyAddress
  )
    FoundationTreasuryNode(treasury)
    NFTMarketCore(feth)
    NFTMarketCreators(royaltyRegistry)
    NFTMarketReserveAuction(duration)
    NFTMarketPrivateSale(proxyAddress) // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize() public initializer {
    NFTMarketAuction._initializeNFTMarketAuction();
  }

  /**
   * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
   * This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyNow)
    returns (address payable)
  {
    return super._getSellerFor(nftContract, tokenId);
  }

  /**
   * @dev Notify implementors of _auctionStarted on auction kick-off.
   * This is a no-op function required to avoid compile errors.
   */
  function _auctionStarted(address nftContract, uint256 tokenId)
    internal
    virtual
    override(NFTMarketCore, NFTMarketBuyNow, NFTMarketOffer)
  {
    super._auctionStarted(nftContract, tokenId);
  }

  /**
   * @dev Notify implementors of _offerAccepted when an offer in escrow is accepted.
   * This is a no-op function required to avoid compile errors.
   */
  function _offerAccepted(address nftContract, uint256 tokenId)
    internal
    virtual
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyNow)
  {
    super._offerAccepted(nftContract, tokenId);
  }

  /**
   * @dev Notify implementors of _buyNowPriceMet when an NFT is sold with BuyNow.
   * This is a no-op function required to avoid compile errors.
   */
  function _buyNowPriceMet(
    address nftContract,
    uint256 tokenId,
    address buyer
  ) internal virtual override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketOffer) {
    super._buyNowPriceMet(nftContract, tokenId, buyer);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error FoundationTreasuryNode_Address_Is_Not_A_Contract();

/**
 * @notice A mixin that stores a reference to the Foundation treasury contract.
 */
abstract contract FoundationTreasuryNode is Initializable {
  using AddressUpgradeable for address payable;

  address payable private ____gap_was_treasury;

  address payable private immutable TREASURY;

  constructor(address payable _treasury) {
    if (!_treasury.isContract()) {
      revert FoundationTreasuryNode_Address_Is_Not_A_Contract();
    }
    TREASURY = _treasury;
  }

  /**
   * @notice Returns the address of the Foundation treasury.
   */
  function getFoundationTreasury() public view returns (address payable) {
    return TREASURY;
  }

  // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../../interfaces/IAdminRole.sol";

import "../FoundationTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the admin role defined by the Foundation treasury.
 */
abstract contract FoundationAdminRole is FoundationTreasuryNode {
  // This file uses 0 data slots (other than what's included via FoundationTreasuryNode)

  modifier onlyFoundationAdmin() {
    require(isAdmin(msg.sender), "FoundationAdminRole: caller does not have the Admin role");
    _;
  }

  /**
   * @notice Returns true if the user is a Foundation admin.
   * @dev This API may be consumed by 3rd party contracts.
   */
  function isAdmin(address user) public view returns (bool) {
    return IAdminRole(getFoundationTreasury()).isAdmin(user);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../../interfaces/IOperatorRole.sol";

import "../FoundationTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the Foundation treasury.
 */
abstract contract FoundationOperatorRole is FoundationTreasuryNode {
  // This file uses 0 data slots (other than what's included via FoundationTreasuryNode)

  function _isFoundationOperator() internal view returns (bool) {
    return IOperatorRole(getFoundationTreasury()).isOperator(msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IFethMarket.sol";
import "./Constants.sol";

error NFTMarketCore_FETH_Address_Is_Not_A_Contract();
error NFTMarketCore_Only_FETH_Can_Transfer_ETH(address sender);

/**
 * @notice A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore is Constants {
  using AddressUpgradeable for address;

  /// @notice The FETH ERC-20 token for managing escrow and lockup.
  IFethMarket public immutable feth;

  constructor(address _feth) {
    if (!_feth.isContract()) {
      revert NFTMarketCore_FETH_Address_Is_Not_A_Contract();
    }
    feth = IFethMarket(_feth);
  }

  /**
   * @notice Only used by FETH. Any direct transfer from users will revert.
   */
  receive() external payable {
    if (msg.sender != address(feth)) {
      revert NFTMarketCore_Only_FETH_Can_Transfer_ETH(msg.sender);
    }
  }

  /**
   * @dev If the NFT did not have an escrowed seller to return, this falls back to return the current owner.
   * This allows functions to calculate the correct fees before the NFT has been listed in auction.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address payable) {
    return payable(IERC721(nftContract).ownerOf(tokenId));
  }

  /**
   * @dev Returns true if the NFT is available in auction and no bids have been placed yet.
   */
  function _hasAuctionReservePrice(
    address, /*nftContract*/
    uint256 /*tokenId*/
  ) internal view virtual returns (bool);

  /**
   * @dev Returns true if the NFT has a valid buy now price set.
   */
  function _hasBuyNowPrice(
    address, /*nftContract*/
    uint256 /*tokenId*/
  ) internal view virtual returns (bool);

  /**
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  function _auctionStarted(
    address, /*nftContract*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @dev Implementors of this interface should update internal state to reflect a buy now offer has been met.
   */
  function _buyNowPriceMet(
    address, /*nftContract*/
    uint256, /*tokenId*/
    address /*buyer*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @dev Implementors of this interface should update internal state to reflect an offer in escrow has been accepted.
   */
  function _offerAccepted(
    address, /*nftContract*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount * MIN_PERCENT_INCREMENT_IN_BASIS_POINTS;

    // Since minIncrement reduces from the currentAmount, this block cannot overflow.
    unchecked {
      minIncrement /= BASIS_POINTS;
      if (minIncrement == 0) {
        // The next amount must be at least 1 wei greater than the current.
        return currentAmount + 1;
      }
    }

    return minIncrement + currentAmount;
  }

  /**
   * @dev Checks if an escrowed NFT is currently in active auction.
   * This returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view virtual returns (bool);

  // 50 slots were consumed by adding ReentrancyGuard
  uint256[950] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

error SendValueWithFallbackWithdraw_No_Funds_Available();

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;

  mapping(address => uint256) private pendingWithdrawals;

  event WithdrawPending(address indexed user, uint256 amount);
  event Withdrawal(address indexed user, uint256 amount);

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   */
  function getPendingWithdrawal(address user) public view returns (uint256) {
    return pendingWithdrawals[user];
  }

  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
   */
  function withdraw() public {
    withdrawFor(payable(msg.sender));
  }

  /**
   * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
   */
  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = pendingWithdrawals[user];
    if (amount == 0) {
      revert SendValueWithFallbackWithdraw_No_Funds_Available();
    }
    pendingWithdrawals[user] = 0;
    user.sendValue(amount);
    emit Withdrawal(user, amount);
  }

  /**
   * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
   * which is enough to send to contracts as well.
   */
  function _sendValueWithFallbackWithdrawWithLowGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 20000);
  }

  /**
   * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
   * which is enough for a 5-way split.
   */
  function _sendValueWithFallbackWithdrawWithMediumGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 210000);
  }

  /**
   * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) private {
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

  uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IFNDNFT721.sol";
import "../interfaces/ITokenCreator.sol";
import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IGetFees.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IRoyaltyInfo.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./OZ/ERC165Checker.sol";

import "./Constants.sol";

error NFTMarketCreators_Address_Does_Not_Support_IRoyaltyRegistry();

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
  Constants,
  ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
  using ERC165Checker for address;

  IRoyaltyRegistry private immutable royaltyRegistry;

  constructor(address _royaltyRegistry) {
    if (!_royaltyRegistry.supportsInterface(type(IRoyaltyRegistry).interfaceId)) {
      revert NFTMarketCreators_Address_Does_Not_Support_IRoyaltyRegistry();
    }
    royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
  }

  /**
   * @dev Returns the destination address for any payments to the creator,
   * or address(0) if the destination is unknown.
   * It also checks if the current seller is the creator for isPrimary checks.
   */
  // solhint-disable-next-line code-complexity
  function _getCreatorPaymentInfo(
    address nftContract,
    uint256 tokenId,
    address seller
  )
    internal
    view
    returns (
      address payable[] memory recipients,
      uint256[] memory splitPerRecipientInBasisPoints,
      bool isCreator
    )
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

    // 2nd priority: getRoyalties
    if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
      try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients,
        uint256[] memory recipientBasisPoints
      ) {
        if (_recipients.length > 0 && _recipients.length == recipientBasisPoints.length) {
          bool hasRecipient;
          unchecked {
            for (uint256 i = 0; i < _recipients.length; i++) {
              if (_recipients[i] != address(0)) {
                hasRecipient = true;
                if (_recipients[i] == seller) {
                  return (_recipients, recipientBasisPoints, true);
                }
              }
            }
          }
          if (hasRecipient) {
            recipients = _recipients;
            splitPerRecipientInBasisPoints = recipientBasisPoints;
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    /* Overrides must support ERC-165 when registered, except for overrides defined by the registry owner.
       If that results in an override w/o 165 we may need to upgrade the market to support or ignore that override. */
    // The registry requires overrides are not 0 and contracts when set.
    // If no override is set, the nftContract address is returned.
    if (recipients.length == 0) {
      try royaltyRegistry.getRoyaltyLookupAddress{ gas: READ_ONLY_GAS_LIMIT }(nftContract) returns (
        address overrideContract
      ) {
        if (overrideContract != nftContract) {
          nftContract = overrideContract;

          // The functions above are repeated here if an override is set.

          // 3rd priority: ERC-2981 override
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

          // 4th priority: getRoyalties override
          if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
            try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
              address payable[] memory _recipients,
              uint256[] memory recipientBasisPoints
            ) {
              if (_recipients.length > 0 && _recipients.length == recipientBasisPoints.length) {
                bool hasRecipient;
                for (uint256 i = 0; i < _recipients.length; i++) {
                  if (_recipients[i] != address(0)) {
                    hasRecipient = true;
                    if (_recipients[i] == seller) {
                      return (_recipients, recipientBasisPoints, true);
                    }
                  }
                }
                if (hasRecipient) {
                  recipients = _recipients;
                  splitPerRecipientInBasisPoints = recipientBasisPoints;
                }
              }
            } catch // solhint-disable-next-line no-empty-blocks
            {
              // Fall through
            }
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Ignore out of gas errors and continue using the nftContract address
      }
    }

    // 5th priority: getFee* from contract or override
    if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetFees).interfaceId)) {
      try IGetFees(nftContract).getFeeRecipients{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients
      ) {
        if (_recipients.length > 0) {
          try IGetFees(nftContract).getFeeBps{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            uint256[] memory recipientBasisPoints
          ) {
            if (_recipients.length == recipientBasisPoints.length) {
              bool hasRecipient;
              unchecked {
                for (uint256 i = 0; i < _recipients.length; i++) {
                  if (_recipients[i] != address(0)) {
                    hasRecipient = true;
                    if (_recipients[i] == seller) {
                      return (_recipients, recipientBasisPoints, true);
                    }
                  }
                }
              }
              if (hasRecipient) {
                recipients = _recipients;
                splitPerRecipientInBasisPoints = recipientBasisPoints;
              }
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 6th priority: tokenCreator w/ or w/o requiring 165 from contract or override
    try IFNDNFT721(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (address payable _creator) {
      if (_creator != address(0)) {
        if (recipients.length == 0) {
          // Only pay the tokenCreator if there wasn't another royalty defined
          recipients = new address payable[](1);
          recipients[0] = _creator;
          // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
        }
        return (recipients, splitPerRecipientInBasisPoints, _creator == seller);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // 7th priority: owner from contract or override
    try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address owner) {
      if (recipients.length == 0) {
        // Only pay the owner if there wasn't another royalty defined
        recipients = new address payable[](1);
        recipients[0] = payable(owner);
        // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
      }
      return (recipients, splitPerRecipientInBasisPoints, owner == seller);
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // If no valid payment address or creator is found, return 0 recipients
  }

  /**
   * @notice Returns the address of the registry allowing for royalty configuration overrides.
   */
  function getRoyaltyRegistry() public view returns (address) {
    return address(royaltyRegistry);
  }

  // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
  uint256[500] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./FoundationTreasuryNode.sol";
import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
  Constants,
  Initializable,
  FoundationTreasuryNode,
  NFTMarketCore,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw
{
  uint256 private ____gap_was_primaryFoundationFeeBasisPoints;
  uint256 private ____gap_was_secondaryFoundationFeeBasisPoints;
  uint256 private ____gap_was_secondaryCreatorFeeBasisPoints;

  mapping(address => mapping(uint256 => bool)) private nftContractToTokenIdToFirstSaleCompleted;

  uint256 private constant PRIMARY_FOUNDATION_FEE_BASIS_POINTS = 1500; // 15%
  uint256 private constant SECONDARY_FOUNDATION_FEE_BASIS_POINTS = 500; // 5%
  uint256 private constant SECONDARY_CREATOR_FEE_BASIS_POINTS = 1000; // 10%

  /**
   * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
   */
  function getIsPrimary(address nftContract, uint256 tokenId) public view returns (bool isPrimary) {
    address payable seller = _getSellerFor(nftContract, tokenId);
    bool isCreator;
    (, , isCreator) = _getCreatorPaymentInfo(nftContract, tokenId, seller);
    isPrimary = isCreator && !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId];
  }

  /**
   * @notice Returns the current fee configuration in basis points.
   */
  function getFeeConfig()
    public
    pure
    returns (
      uint256 primaryFoundationFeeBasisPoints,
      uint256 secondaryFoundationFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    )
  {
    return (
      PRIMARY_FOUNDATION_FEE_BASIS_POINTS,
      SECONDARY_FOUNDATION_FEE_BASIS_POINTS,
      SECONDARY_CREATOR_FEE_BASIS_POINTS
    );
  }

  /**
   * @notice Returns how funds will be distributed for an Auction sale at the given price point.
   * @dev This is required for backwards compatibility with subgraph.
   */
  function getFees(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    public
    view
    returns (
      uint256 foundationFee,
      uint256 creatorRev,
      uint256 ownerRev
    )
  {
    address payable seller = _getSellerFor(nftContract, tokenId);
    (foundationFee, , , creatorRev, , ownerRev) = _getFees(nftContract, tokenId, seller, price);
  }

  /**
   * @dev Calculates how funds should be distributed for the given sale details.
   */
  function _getFees(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    private
    view
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
    (creatorRecipients, creatorShares, isCreator) = _getCreatorPaymentInfo(nftContract, tokenId, seller);
    bool isPrimary = isCreator && !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId];

    // The SafeMath usage below should only be applicable if a huge (unrealistic) price is used
    // or fees are misconfigured.

    // Calculate the Foundation fee
    foundationFee =
      (price * (isPrimary ? PRIMARY_FOUNDATION_FEE_BASIS_POINTS : SECONDARY_FOUNDATION_FEE_BASIS_POINTS)) /
      BASIS_POINTS;

    // Calculate the Creator revenue.
    if (isPrimary) {
      creatorRev = price - foundationFee;
      // The owner is the creator so ownerRev is not broken out here.
    } else {
      if (creatorRecipients.length > 0) {
        if (isCreator) {
          // Non-primary sales by the creator should go to the payment address.
          creatorRev = price - foundationFee;
        } else {
          creatorRev = (price * SECONDARY_CREATOR_FEE_BASIS_POINTS) / BASIS_POINTS;
          // If a secondary sale, calculate the owner revenue.
          ownerRevTo = seller;
          ownerRev = price - foundationFee - creatorRev;
        }
      } else {
        // If a secondary sale, calculate the owner revenue.
        ownerRevTo = seller;
        ownerRev = price - foundationFee;
      }
    }
  }

  /**
   * @dev Distributes funds to foundation, creator, and NFT owner after a sale.
   * This call will respect the creator's payment address if defined.
   */
  // solhint-disable-next-line code-complexity
  function _distributeFunds(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    internal
    returns (
      uint256 foundationFee,
      uint256 creatorFee,
      uint256 ownerRev
    )
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

    // Anytime fees are distributed that indicates the first sale is complete,
    // which will not change state during a secondary sale.
    // This must come after the `_getFees` call above as this state is considered in the function.
    nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;

    _sendValueWithFallbackWithdrawWithLowGasLimit(getFoundationTreasury(), foundationFee);

    if (creatorFee > 0) {
      if (creatorRecipients.length > 1) {
        uint256 maxCreatorIndex = creatorRecipients.length - 1;
        if (maxCreatorIndex > MAX_CREATOR_INDEX) {
          maxCreatorIndex = MAX_CREATOR_INDEX;
        }

        // Determine the total shares defined so it can be leveraged to distribute below
        uint256 totalShares;
        unchecked {
          for (uint256 i = 0; i <= maxCreatorIndex; i++) {
            if (creatorShares[i] > BASIS_POINTS) {
              // If the numbers are >100% we ignore the fee recipients and pay just the first instead
              maxCreatorIndex = 0;
              break;
            }
            totalShares += creatorShares[i];
          }
        }
        if (totalShares == 0) {
          maxCreatorIndex = 0;
        }

        // Send payouts to each additional recipient if more than 1 was defined
        uint256 totalDistributed;
        for (uint256 i = 1; i <= maxCreatorIndex; i++) {
          uint256 share = (creatorFee * creatorShares[i]) / totalShares;
          totalDistributed += share;
          _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[i], share);
        }

        // Send the remainder to the 1st creator, rounding in their favor
        _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[0], creatorFee - totalDistributed);
      } else {
        _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[0], creatorFee);
      }
    }
    _sendValueWithFallbackWithdrawWithMediumGasLimit(ownerRevTo, ownerRev);
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
  /**
   * @dev A global id for auctions of any type.
   */
  uint256 private nextAuctionId;

  function _initializeNFTMarketAuction() internal {
    nextAuctionId = 1;
  }

  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    unchecked {
      return nextAuctionId++;
    }
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarketAuction.sol";
import "./roles/FoundationAdminRole.sol";
import "./AccountMigration.sol";

/**
 * @notice Custom Errors defined for NFTMarketReserveAuction.
 */
error NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
error NFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
error NFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
error NFTMarketReserveAuction_Auction_Already_Created(uint256 auctionId);
error NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
error NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(address owner);
error NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
error NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
error NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
error NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
error NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
error NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Migrate_Non_Matching_Seller(address seller);

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
  Constants,
  FoundationAdminRole,
  AccountMigration,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction
{
  struct ReserveAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 duration;
    uint256 extensionDuration;
    uint256 endTime;
    address payable bidder;
    uint256 amount;
  }

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  mapping(uint256 => ReserveAuction) private auctionIdToAuction;

  // These variables were used in an older version of the contract, left here as a gap to ensure upgrade compatibility
  uint256 private ______gap_was_minPercentIncrementInBasisPoints;
  uint256 private ______gap_was_maxBidIncrementRequirement;
  uint256 private ______gap_was_duration;
  uint256 private ______gap_was_extensionDuration;
  uint256 private ______gap_was_goLiveDate;

  // Cap the max duration so that overflows will not occur
  uint256 private constant MAX_MAX_DURATION = 1000 days;

  uint256 private constant EXTENSION_DURATION = 15 minutes;

  uint256 private immutable DURATION;

  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionInvalidated(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  event ReserveAuctionSellerMigrated(
    uint256 indexed auctionId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );

  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    if (reservePrice == 0) {
      revert NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
    }
    _;
  }

  constructor(uint256 duration) {
    if (duration > MAX_MAX_DURATION) {
      revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
    }
    if (duration < EXTENSION_DURATION) {
      revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
    }
    DURATION = duration;
  }

  /**
   * @notice Returns auction details for a given auctionId.
   */
  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory) {
    return auctionIdToAuction[auctionId];
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   */
  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) public view returns (uint256) {
    return nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow,
   * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = auctionIdToAuction[nftContractToTokenIdToAuctionId[nftContract][tokenId]].seller;
    if (seller == address(0)) {
      return super._getSellerFor(nftContract, tokenId);
    }
    return seller;
  }

  /**
   * @notice Returns the current configuration for reserve auctions.
   */
  function getReserveAuctionConfig() public view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration) {
    minPercentIncrementInBasisPoints = MIN_PERCENT_INCREMENT_IN_BASIS_POINTS;
    duration = DURATION;
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) public onlyValidAuctionConfig(reservePrice) nonReentrant {
    if (getReserveAuctionIdFor(nftContract, tokenId) != 0) {
      revert NFTMarketReserveAuction_Auction_Already_Created(getReserveAuctionIdFor(nftContract, tokenId));
    }

    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
    uint256 auctionId = _getNextAndIncrementAuctionId();

    // Check if already escrowed.
    if (!_hasBuyNowPrice(nftContract, tokenId)) {
      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
    auctionIdToAuction[auctionId] = ReserveAuction(
      nftContract,
      tokenId,
      payable(msg.sender),
      DURATION,
      EXTENSION_DURATION,
      0, // endTime is only known once the reserve price is met
      payable(0), // bidder is only known once a bid has been placed
      reservePrice
    );

    emit ReserveAuctionCreated(msg.sender, nftContract, tokenId, DURATION, EXTENSION_DURATION, reservePrice, auctionId);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the configuration
   * such as the reservePrice may be changed by the seller.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) public onlyValidAuctionConfig(reservePrice) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * The NFT is returned to the seller from escrow.
   */
  function cancelReserveAuction(uint256 auctionId) public nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!_hasBuyNowPrice(auction.nftContract, auction.tokenId)) {
      IERC721(auction.nftContract).transferFrom(address(this), msg.sender, auction.tokenId);
    }
    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBid(uint256 auctionId) public payable nonReentrant {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.amount == 0) {
      revert NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
    }

    if (auction.endTime == 0) {
      // If this is the first bid, ensure it's >= the reserve price
      if (auction.amount > msg.value) {
        revert NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(auction.amount);
      }
      // Notify implementors of _auctionStarted on auction kick-off.
      _auctionStarted(auction.nftContract, auction.tokenId);
    } else {
      // If this bid outbids another, confirm that the bid is at least x% greater than the last
      if (auction.endTime < block.timestamp) {
        revert NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(auction.endTime);
      }
      if (auction.bidder == msg.sender) {
        revert NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      }
      if (msg.value < _getMinIncrement(auction.amount)) {
        revert NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(_getMinIncrement(auction.amount));
      }
    }

    if (auction.endTime == 0) {
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);
      // On the first bid, the endTime is now + duration
      unchecked {
        auction.endTime = block.timestamp + auction.duration;
      }
    } else {
      // Cache and update bidder state before a possible reentrancy (via the value transfer)
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);

      // When a bid outbids another, check to see if a time extension should apply.
      unchecked {
        if (auction.endTime - block.timestamp < auction.extensionDuration) {
          auction.endTime = block.timestamp + auction.extensionDuration;
        }
      }

      // Refund the previous bidder
      _sendValueWithFallbackWithdrawWithLowGasLimit(originalBidder, originalAmount);
    }

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, msg.value, auction.endTime);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute funds.
   */
  function finalizeReserveAuction(uint256 auctionId) public nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
    }
    if (auction.endTime >= block.timestamp) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    IERC721(auction.nftContract).transferFrom(address(this), auction.bidder, auction.tokenId);

    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      auction.nftContract,
      auction.tokenId,
      auction.seller,
      auction.amount
    );

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   * Bids must be greater than or equal to this value or they will revert.
   */
  function getMinBidAmount(uint256 auctionId) external view returns (uint256) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

  /**
   * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to
   * the seller (if not active buy price set).
   * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
   */
  function adminCancelReserveAuction(uint256 auctionId, string memory reason) public onlyFoundationAdmin {
    if (bytes(reason).length == 0) {
      revert NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
    }
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.amount == 0) {
      revert NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!_hasBuyNowPrice(auction.nftContract, auction.tokenId)) {
      IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
    }
    if (auction.bidder != address(0)) {
      _sendValueWithFallbackWithdrawWithMediumGasLimit(auction.bidder, auction.amount);
    }

    emit ReserveAuctionCanceledByAdmin(auctionId, reason);
  }

  /**
   * @notice Allows an NFT owner and Foundation to work together in order to update the seller
   * for auctions they have listed to a new account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any auctions that have already been finalized.
   */
  function adminAccountMigration(
    uint256[] calldata listedAuctionIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    unchecked {
      for (uint256 i = 0; i < listedAuctionIds.length; i++) {
        uint256 auctionId = listedAuctionIds[i];
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        // The seller would be 0 if it was finalized before this call
        if (auction.seller != address(0)) {
          if (auction.seller != originalAddress) {
            revert NFTMarketReserveAuction_Cannot_Migrate_Non_Matching_Seller(auction.seller);
          }
          auction.seller = newAddress;
          emit ReserveAuctionSellerMigrated(auctionId, originalAddress, newAddress);
        }
      }
    }
  }

  /**
   * @dev Returns true if the NFT is available in auction and no bids have been placed yet.
   */
  function _hasAuctionReservePrice(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0 && auctionIdToAuction[auctionId].endTime == 0) {
      return true;
    }
    return false;
  }

  /**
   * @dev Checks if an escrowed NFT is currently in active auction.
   * This returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      return false;
    }
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    return auction.endTime >= block.timestamp;
  }

  /**
   * @dev Clears auction status and emits a ReserveAuctionInvalidated on a buy now price met.
   */
  function _buyNowPriceMet(
    address nftContract,
    uint256 tokenId,
    address buyer
  ) internal virtual override {
    _invalidateAuction(nftContract, tokenId);
    super._buyNowPriceMet(nftContract, tokenId, buyer);
  }

  /**
   * @dev When an offer in escrow is accepted, we may need to invalidate the auction's reserve price.
   */
  function _offerAccepted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateAuction(nftContract, tokenId);
    super._offerAccepted(nftContract, tokenId);
  }

  /**
   * @dev Invalidates an auction if one is found.
   */
  function _invalidateAuction(address nftContract, uint256 tokenId) private {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0) {
      delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
      delete auctionIdToAuction[auctionId];
      emit ReserveAuctionInvalidated(auctionId);
    }
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFTMarketFees.sol";

error NFTMarketPrivateSale_Proxy_Address_Is_Not_A_Contract();
error NFTMarketPrivateSale_Sale_Expired();
error NFTMarketPrivateSale_Signature_Verification_Failed();

/**
 * @notice Adds support for a private sale of an NFT directly between two parties.
 */
abstract contract NFTMarketPrivateSale is NFTMarketFees {
  using AddressUpgradeable for address;

  /**
   * @dev This name is used in the EIP-712 domain.
   * If multiple classes use EIP-712 signatures in the future this can move to the shared constants file.
   */
  string private constant NAME = "FNDNFTMarket";
  /**
   * @dev This is a hash of the method signature used in the EIP-712 signature for private sales.
   */
  bytes32 private constant BUY_FROM_PRIVATE_SALE_TYPEHASH =
    keccak256("BuyFromPrivateSale(address nftContract,uint256 tokenId,address buyer,uint256 price,uint256 deadline)");

  bytes32 private ____gap_was_DOMAIN_SEPARATOR;

  /**
   * @dev This is the domain used in EIP-712 signatures.
   * It is not a constant so that the chainId can be determined dynamically.
   * If multiple classes use EIP-712 signatures in the future this can move to a shared file.
   */
  bytes32 private immutable DOMAIN_SEPARATOR;

  event PrivateSaleFinalized(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev,
    uint256 deadline
  );

  constructor(address proxyAddress) {
    if (!proxyAddress.isContract()) {
      revert NFTMarketPrivateSale_Proxy_Address_Is_Not_A_Contract();
    }
    uint256 chainId;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(NAME)),
        keccak256(bytes("1")),
        chainId,
        proxyAddress
      )
    );
  }

  /**
   * @notice Allow two parties to execute a private sale.
   * @dev The seller signs a message approving the sale, and then the buyer calls this function
   * with the msg.value equal to the agreed upon price.
   * The sale is executed in this single on-chain call including the transfer of funds and the NFT.
   */
  function buyFromPrivateSale(
    IERC721 nftContract,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable nonReentrant {
    // The signed message from the seller is only valid for a limited time.
    if (deadline < block.timestamp) {
      revert NFTMarketPrivateSale_Sale_Expired();
    }
    // The seller must have the NFT in their wallet when this function is called.
    address payable seller = payable(nftContract.ownerOf(tokenId));

    // Scoping this block to avoid a stack too deep error
    {
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(BUY_FROM_PRIVATE_SALE_TYPEHASH, nftContract, tokenId, msg.sender, msg.value, deadline))
        )
      );
      // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
      if (ecrecover(digest, v, r, s) != seller) {
        revert NFTMarketPrivateSale_Signature_Verification_Failed();
      }
    }

    // This will revert if the seller has not given the market contract approval.
    nftContract.transferFrom(seller, msg.sender, tokenId);
    // Pay the seller, creator, and Foundation as appropriate.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      address(nftContract),
      tokenId,
      seller,
      msg.value
    );

    emit PrivateSaleFinalized(
      address(nftContract),
      tokenId,
      seller,
      msg.sender,
      f8nFee,
      creatorFee,
      ownerRev,
      deadline
    );
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Constants.sol";
import "./NFTMarketFees.sol";
import "./NFTMarketCore.sol";

/**
 * @notice Custom Errors defined for NFTMarketBuyNow.
 */
error NFTMarketBuyNow_Only_Owner_Can_Set_Price(address owner);
error NFTMarketBuyNow_Only_Owner_Can_Cancel_Price(address owner);
error NFTMarketBuyNow_Cannot_Buy_Unset_Price();
error NFTMarketBuyNow_Cannot_Buy_At_Different_Price(uint256 buyNowPrice);
error NFTMarketBuyNow_Cannot_Cancel_Unset_Price();

/**
 * @notice Adds support for a buy now price for an NFT.
 */
abstract contract NFTMarketBuyNow is NFTMarketCore, NFTMarketFees {
  struct BuyNow {
    address payable seller;
    uint96 amount;
  }

  mapping(address => mapping(uint256 => BuyNow)) private nftContractToTokenIdToBuyNow;

  event BuyPriceSet(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 amount);
  event BuyPriceCanceled(address indexed nftContract, uint256 indexed tokenId);
  event BuyPriceInvalidated(address indexed nftContract, uint256 indexed tokenId);
  event BuyPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );

  /**
   * @notice Set the buy now price for an NFT and escrows in the market.
   * @dev Setting a 0x0 address for the seller and 0 for amount will clear the set buy now state for the NFT;
   * however, will not remove the NFT from escrow.
   * The first bid that kicks off an auction also clears the buy now price for the NFT.
   */
  function setBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external {
    address seller = _getSellerFor(nftContract, tokenId);
    if (seller != msg.sender) {
      revert NFTMarketBuyNow_Only_Owner_Can_Set_Price(seller);
    }

    seller = nftContractToTokenIdToBuyNow[nftContract][tokenId].seller;
    nftContractToTokenIdToBuyNow[nftContract][tokenId] = BuyNow(payable(msg.sender), uint96(amount));
    if (seller != msg.sender && !_hasAuctionReservePrice(nftContract, tokenId)) {
      // Escrow the NFT onto the FND Market, if not already escrowed.
      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }
    emit BuyPriceSet(nftContract, tokenId, msg.sender, amount);
  }

  /**
   * @notice Buy the NFT at the set buy now price.
   * @dev The `amount` param is currently not used,
   * it is included for compatibility for when we introduce buying with FETH.
   * TODO: Use `amount` when buying with FETH,
   * if buying with FETH not implemented add require() before mainnet launch.
   */
  function buy(
    address nftContract,
    uint256 tokenId,
    uint256 /*amount*/
  ) external payable nonReentrant {
    BuyNow memory curBuyNow = nftContractToTokenIdToBuyNow[nftContract][tokenId];
    if (curBuyNow.seller == address(0)) {
      revert NFTMarketBuyNow_Cannot_Buy_Unset_Price();
    }
    if (msg.value != curBuyNow.amount) {
      revert NFTMarketBuyNow_Cannot_Buy_At_Different_Price(curBuyNow.amount);
    }

    // clear internal state.
    delete nftContractToTokenIdToBuyNow[nftContract][tokenId];
    // Notify implementors of _buyNowPriceMet on buy now.
    _buyNowPriceMet(nftContract, tokenId, msg.sender);
    // transfer NFT from escrow to msg.sender.
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

    // Pay the seller, creator and Foundation as appropriate.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      address(nftContract),
      tokenId,
      curBuyNow.seller,
      msg.value
    );
    emit BuyPriceAccepted(nftContract, tokenId, curBuyNow.seller, msg.sender, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @notice If the NFT has a buy now set and the seller match, clears buy now state for the NFT.
   * If the NFT is not listed in an auction, returns back the NFT to the original owner from escrow.
   */
  function cancelBuyPrice(address nftContract, uint256 tokenId) public nonReentrant {
    address seller = nftContractToTokenIdToBuyNow[nftContract][tokenId].seller;
    if (seller == address(0)) {
      revert NFTMarketBuyNow_Cannot_Cancel_Unset_Price();
    }
    if (seller != msg.sender) {
      revert NFTMarketBuyNow_Only_Owner_Can_Cancel_Price(seller);
    }

    // Transfer back NFT to owner.
    delete nftContractToTokenIdToBuyNow[nftContract][tokenId];
    // Make sure not escrowed for anything else before transferring NFT back to owner.
    if (!_hasAuctionReservePrice(nftContract, tokenId)) {
      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }

    emit BuyPriceCanceled(nftContract, tokenId);
  }

  /**
   * @notice Returns the buy now price for an NFT if one is available, max UINT256 otherwise.
   */
  function getBuyPrice(address nftContract, uint256 tokenId) external view returns (uint256 amount) {
    if (nftContractToTokenIdToBuyNow[nftContract][tokenId].seller == address(0)) {
      return type(uint256).max;
    }
    return nftContractToTokenIdToBuyNow[nftContract][tokenId].amount;
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow,
   * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyNow[nftContract][tokenId].seller;
    if (seller == address(0)) {
      return super._getSellerFor(nftContract, tokenId);
    }
  }

  /**
   * @dev Returns true if the NFT has a valid buy now price set.
   */
  function _hasBuyNowPrice(address nftContract, uint256 tokenId) internal view override returns (bool) {
    return nftContractToTokenIdToBuyNow[nftContract][tokenId].seller != address(0);
  }

  /**
   * @dev Clears buy now price set and emits a BuyPriceInvalidated on a auction start.
   */
  function _auctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateBuyNow(nftContract, tokenId);
    super._auctionStarted(nftContract, tokenId);
  }

  /**
   * @dev Clears the buy now price set and emits a BuyPriceInvalidated when an escrowed NFT is purchased via offers.
   */
  function _offerAccepted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateBuyNow(nftContract, tokenId);
    super._offerAccepted(nftContract, tokenId);
  }

  /**
   * @dev Clear a buy now price and emit BuyPriceInvalidated if one is found.
   */
  function _invalidateBuyNow(address nftContract, uint256 tokenId) private {
    if (nftContractToTokenIdToBuyNow[nftContract][tokenId].seller != address(0)) {
      delete nftContractToTokenIdToBuyNow[nftContract][tokenId];
      emit BuyPriceInvalidated(nftContract, tokenId);
    }
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./NFTMarketFees.sol";
import "./NFTMarketCore.sol";
import "./roles/FoundationAdminRole.sol";
import "../FETH.sol";

error NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);
error NFTMarketOffer_Offer_Expired(uint256 expiry);
error NFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
error NFTMarketOffer_Reason_Required();
error NFTMarketOffer_In_Active_Auction();
error NFTMarketOffer_Only_Owner_Can_Accept(address owner);

/**
 * @notice Allows collectors to make an offer for an NFT, valid for 24-25 hours.
 * Funds are escrowed in the FETH contract.
 */
abstract contract NFTMarketOffer is FoundationAdminRole, NFTMarketCore, ReentrancyGuardUpgradeable, NFTMarketFees {
  using AddressUpgradeable for address;

  /// @dev Tracks the current highest offer for an NFT.
  struct Offer {
    address buyer;
    uint128 expiration;
    uint128 amount;
  }

  /// @dev Stores per-NFT offers.
  mapping(address => mapping(uint256 => Offer)) private nftContractToIdToOffer;

  event OfferMade(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 amount,
    uint256 expiration
  );
  event OfferAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  event OfferInvalidated(address indexed nftContract, uint256 indexed tokenId);
  event OfferCanceledByAdmin(address indexed nftContract, uint256 indexed tokenId, string reason);

  /**
   * @notice Make an offer for any NFT, funds will be locked in FETH.
   * @dev An offer may be made for an NFT before it is minted.
   */
  function makeOffer(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external payable {
    if (_isInActiveAuction(nftContract, tokenId)) {
      revert NFTMarketOffer_In_Active_Auction();
    }
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];

    uint256 expiration;
    if (offer.expiration >= block.timestamp) {
      // A previous offer exists and has not expired

      if (amount < _getMinIncrement(offer.amount)) {
        // A non-trivial increase in price is required to avoid sniping
        revert NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(_getMinIncrement(offer.amount));
      }

      // Update escrow for the new offer
      expiration = feth.marketChangeDeposit{ value: msg.value }(
        offer.buyer,
        offer.expiration,
        offer.amount,
        msg.sender,
        amount
      );
    } else {
      // Else brand new offer

      // Add offer to escrow
      expiration = feth.marketDepositFor{ value: msg.value }(msg.sender, amount);
    }

    // Record offer details
    offer.buyer = msg.sender;
    offer.expiration = uint128(expiration);
    offer.amount = uint128(amount);
    emit OfferMade(nftContract, tokenId, msg.sender, amount, expiration);
  }

  /**
   * @notice Accept an offer for an NFT.
   * @dev The offer must not be expired and the NFT owned + approved by the seller or in available escrow.
   */
  function acceptOffer(
    address nftContract,
    uint256 tokenId,
    uint256 minAmount
  ) external nonReentrant {
    // Lookup and validate offer details
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration < block.timestamp) {
      revert NFTMarketOffer_Offer_Expired(offer.expiration);
    }
    if (offer.amount < minAmount) {
      revert NFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    }

    // Remove offer
    delete nftContractToIdToOffer[nftContract][tokenId];
    feth.marketWithdrawLocked(offer.buyer, offer.expiration, offer.amount);

    // Settle sale
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      nftContract,
      tokenId,
      payable(msg.sender),
      offer.amount
    );
    try
      IERC721(nftContract).transferFrom(msg.sender, offer.buyer, tokenId) // solhint-disable-next-line no-empty-blocks
    {
      // Happy case
    } catch {
      // If the transfer fails then it might be in escrow
      if (_getSellerFor(nftContract, tokenId) != msg.sender) {
        revert NFTMarketOffer_Only_Owner_Can_Accept(_getSellerFor(nftContract, tokenId));
      }
      // Inform escrow managers to clear their state
      _offerAccepted(nftContract, tokenId);
      IERC721(nftContract).transferFrom(address(this), offer.buyer, tokenId);
    }

    emit OfferAccepted(nftContract, tokenId, offer.buyer, msg.sender, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @notice Allows Foundation to cancel offers.
   * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
   */
  function adminCancelOffers(
    address[] calldata nftContracts,
    uint256[] calldata tokenIds,
    string memory reason
  ) external onlyFoundationAdmin {
    if (bytes(reason).length == 0) {
      revert NFTMarketOffer_Reason_Required();
    }

    // The array length cannot overflow 256 bits
    unchecked {
      for (uint256 i = 0; i < nftContracts.length; i++) {
        Offer memory offer = nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];
        delete nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];

        if (offer.expiration >= block.timestamp) {
          // Unlock from escrow and emit an event only if the offer is still active
          feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);
          emit OfferCanceledByAdmin(nftContracts[i], tokenIds[i], reason);
        }
        // Else continue on so the rest of the batch transaction can process successfully
      }
    }
  }

  /**
   * @dev Invalidates the offer when an auction is kicked off.
   */
  function _auctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];
    _invalidateOffer(nftContract, tokenId, offer);
    super._auctionStarted(nftContract, tokenId);
  }

  /**
   * @dev Invalidates the offer when the offerer uses buy now instead.
   * If the offer is by a different user, it remains active for the new owner to consider.
   */
  function _buyNowPriceMet(
    address nftContract,
    uint256 tokenId,
    address buyer
  ) internal virtual override {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.buyer == buyer) {
      _invalidateOffer(nftContract, tokenId, offer);
    }
    super._buyNowPriceMet(nftContract, tokenId, buyer);
  }

  /**
   * @dev Invalidates the offer and frees from escrow if it is still active.
   */
  function _invalidateOffer(
    address nftContract,
    uint256 tokenId,
    Offer memory offer
  ) private {
    if (offer.expiration >= block.timestamp) {
      delete nftContractToIdToOffer[nftContract][tokenId];
      feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);
      emit OfferInvalidated(nftContract, tokenId);
    }
  }

  /**
   * @notice Returns details about the current highest offer for an NFT.
   * @dev Nothing is returned if there is no offer or the offer has expired.
   */
  function getOffer(address nftContract, uint256 tokenId)
    external
    view
    returns (
      address buyer,
      uint256 expiration,
      uint256 amount
    )
  {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration >= block.timestamp) {
      return (offer.buyer, offer.expiration, offer.amount);
    }
    // Offer not found or has expired
    return (address(0), 0, 0);
  }

  /**
   * @notice Returns the minimum amount a collector must spend to place an offer.
   * Offers must be greater than or equal to this value or they will revert.
   */
  function getMinOfferAmount(address nftContract, uint256 tokenId) external view returns (uint256) {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration >= block.timestamp) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for functions the market uses in FETH.
 */
interface IFethMarket {
  function marketDepositFor(address account, uint256 amount) external payable returns (uint256 expiration);

  function marketWithdrawFrom(address from, uint256 amount) external;

  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketChangeDeposit(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable returns (uint256 expiration);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
  uint256 internal constant BASIS_POINTS = 10000;

  uint256 internal constant MIN_PERCENT_INCREMENT_IN_BASIS_POINTS = 1000; // 10%

  uint256 internal constant READ_ONLY_GAS_LIMIT = 40000;

  /**
   * @dev Support up to 5 royalty recipients. A cap is required to ensure gas costs are not too high
   * when an auction is finalized.
   */
  uint256 internal constant MAX_CREATOR_INDEX = 4;
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

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.8.0;

interface IFNDNFT721 {
  function tokenCreator(uint256 tokenId) external view returns (address payable);

  function getTokenCreatorPaymentAddress(uint256 tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ITokenCreator {
  function tokenCreator(uint256 tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IGetRoyalties {
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
interface IGetFees {
  function getFeeRecipients(uint256 id) external view returns (address payable[] memory);

  function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {

     event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     * 
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external;

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns(address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns(bool);
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

pragma solidity ^0.8.0;

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol
 * Modified to allow checking multiple interfaces w/o checking general 165 support.
 */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
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
    return
      supportsERC165Interface(account, type(IERC165).interfaceId) &&
      !supportsERC165Interface(account, _INTERFACE_ID_INVALID);
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
        for (uint256 i = 0; i < interfaceIds.length; i++) {
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
      for (uint256 i = 0; i < interfaceIds.length; i++) {
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
    bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
    (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/AccountMigrationLibrary.sol";
import "./roles/FoundationOperatorRole.sol";

error AccountMigration_Caller_Is_Not_Operator();

abstract contract AccountMigration is FoundationOperatorRole {
  using AccountMigrationLibrary for address;

  modifier onlyAuthorizedAccountMigration(
    address originalAddress,
    address payable newAddress,
    bytes memory signature
  ) {
    if (!_isFoundationOperator()) {
      revert AccountMigration_Caller_Is_Not_Operator();
    }
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);
    _;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error AccountMigrationLibrary_Cannot_Migrate_Account_To_Itself();
error AccountMigrationLibrary_Signature_Verification_Failed();

/**
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the NFT contracts and FNDNFTMarket, and the same signature authorizes both.
 */
library AccountMigrationLibrary {
  using ECDSA for bytes;
  using SignatureChecker for address;
  using Strings for uint256;

  // From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function _toAsciiString(address x) private pure returns (string memory) {
    unchecked {
      bytes memory s = new bytes(42);
      s[0] = "0";
      s[1] = "x";
      for (uint256 i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i + 2] = _char(hi);
        s[2 * i + 3] = _char(lo);
      }
      return string(s);
    }
  }

  function _char(bytes1 b) private pure returns (bytes1 c) {
    unchecked {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
    }
  }

  /**
   * @dev Confirms the msg.sender is a Foundation operator and that the signature provided is valid.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function requireAuthorizedAccountMigration(
    address originalAddress,
    address newAddress,
    bytes memory signature
  ) internal view {
    if (originalAddress == newAddress) {
      revert AccountMigrationLibrary_Cannot_Migrate_Account_To_Itself();
    }
    bytes32 hash = abi
      .encodePacked("I authorize Foundation to migrate my account to ", _toAsciiString(newAddress))
      .toEthSignedMessageHash();
    if (!originalAddress.isValidSignatureNow(hash, signature)) {
      revert AccountMigrationLibrary_Signature_Verification_Failed();
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IFethMarket.sol";

error FETH_Invalid_Lockup_Duration();

/**
 * @notice An ERC-20 token which wraps ETH, potentially with a 1 day lockup period.
 */
contract FETH is IFethMarket {
  using AddressUpgradeable for address payable;
  using Math for uint256;

  /// @dev Tracks an account's total lockup per expiration time.
  struct LockedBalance {
    uint128 expiration;
    uint128 totalAmount;
  }
  /// @dev Tracks an account's info.
  struct AccountInfo {
    /// @dev The amount of ETH which has been unlocked already.
    uint128 freedBalance;
    /// @dev The first applicable lockup bucket for this account.
    uint128 lockupStartIndex;
    /// @dev Stores up to 25 buckets of locked balance for a user, one per hour.
    mapping(uint256 => LockedBalance) lockups;
    /// @dev Returns the amount which a spender is still allowed to withdraw from this account.
    mapping(address => uint256) allowance;
  }

  // ERC-20 metadata fields
  string public constant name = "Foundation Wrapped Ether";
  string public constant symbol = "FETH";
  uint8 public constant decimals = 18;

  // Lockup configuration
  /// @notice The minimum lockup period in seconds.
  uint256 private immutable lockupDuration;
  /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
  uint256 private immutable lockupInterval;

  /// @notice The Foundation market contract with permissions to manage lockups.
  address payable public immutable foundationMarket;

  /// @dev Stores per-account details.
  mapping(address => AccountInfo) private accountToInfo;

  // ERC-20 events
  event Approval(address indexed from, address indexed spender, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Custom events
  event ETHWithdrawn(address indexed from, address indexed to, uint256 amount);
  event BalanceLocked(address indexed account, uint256 indexed expiration, uint256 amount);
  event BalanceUnlocked(address indexed account, uint256 indexed expiration, uint256 amount);

  /// @dev Allows the Foundation market permission to manage lockups for a user.
  modifier onlyFoundationMarket() {
    require(msg.sender == foundationMarket, "FETH: Only market can call this function");
    _;
  }

  constructor(address payable _foundationMarket, uint256 _lockupDuration) {
    require(_foundationMarket.isContract(), "FETH: Market must be a contract");
    foundationMarket = _foundationMarket;
    lockupDuration = _lockupDuration;
    lockupInterval = _lockupDuration / 24;
    if (lockupInterval * 24 != _lockupDuration || _lockupDuration == 0) {
      revert FETH_Invalid_Lockup_Duration();
    }
  }

  /**
   * @notice Transferring ETH to the contract performs a deposit.
   */
  receive() external payable {
    deposit();
  }

  /**
   * @notice Deposit ETH and receive FETH which is not subject to any lockup period.
   */
  function deposit() public payable {
    AccountInfo storage accountInfo = accountToInfo[msg.sender];
    // ETH value cannot realistically overflow 128 bits
    unchecked {
      accountInfo.freedBalance += uint128(msg.value);
    }
    emit Transfer(address(0), msg.sender, msg.value);
  }

  /**
   * @notice Used by the market contract:
   * Adds funds to an account which are locked for a period of time.
   */
  function marketDepositFor(address account, uint256 amount)
    external
    payable
    onlyFoundationMarket
    returns (uint256 expiration)
  {
    return _marketDepositFor(account, amount);
  }

  /**
   * @notice Used by the market contract:
   * Removes available balance and returns ETH to the caller.
   */
  function marketWithdrawFrom(address from, uint256 amount) external onlyFoundationMarket {
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    _deductFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(from, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract:
   * Removes an account's lockup and returns ETH to the caller.
   */
  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _removeFromLockedBalance(account, expiration, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(account, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract:
   * Remove an account's lockup, making the ETH available.
   */
  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _marketUnlockFor(account, expiration, amount);
  }

  /**
   * @notice Used by the market contract:
   * Remove an account's lockup and deposit a new one, any surplus becomes available.
   */
  function marketChangeDeposit(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable onlyFoundationMarket returns (uint256 expiration) {
    _marketUnlockFor(unlockFrom, unlockExpiration, unlockAmount);
    return _marketDepositFor(depositFor, depositAmount);
  }

  /**
   * @notice Withdraw all ETH available to your account.
   */
  function withdrawAvailableBalance() external {
    AccountInfo storage accountInfo = _freeFromEscrow(msg.sender);
    uint256 amount = accountInfo.freedBalance;
    require(amount > 0, "FETH: Nothing to withdraw");
    delete accountInfo.freedBalance;

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Withdraw the specified amount and sends ETH to the destination address.
   */
  function withdrawFrom(
    address from,
    address payable to,
    uint256 amount
  ) external {
    require(amount > 0, "FETH: Nothing to withdraw");
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowance(accountInfo, amount);
    }
    _deductFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    to.sendValue(amount);

    emit ETHWithdrawn(from, to, amount);
  }

  /**
   * @notice Approves the spender to transfer from your account.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    accountToInfo[msg.sender].allowance[spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Transfers an amount from your account.
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool) {
    require(to != address(0) && to != address(this), "FETH: Transfer to burn not allowed");
    AccountInfo storage fromAccountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowance(fromAccountInfo, amount);
    }
    _deductFrom(fromAccountInfo, amount);
    AccountInfo storage toAccountInfo = accountToInfo[to];

    // Total ETH cannot realistically overflow 128 bits
    unchecked {
      toAccountInfo.freedBalance += uint128(amount);
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @dev Require msg.sender has been approved and deducts the amount from the available allowance.
   */
  function _deductAllowance(AccountInfo storage accountInfo, uint256 amount) private {
    if (accountInfo.allowance[msg.sender] != type(uint256).max) {
      require(accountInfo.allowance[msg.sender] >= amount, "FETH: Insufficient allowance");
      // The require ensures allowance cannot underflow
      unchecked {
        accountInfo.allowance[msg.sender] -= amount;
      }
    }
  }

  /**
   * @dev Removes an amount from the account's available funds.
   */
  function _deductFrom(AccountInfo storage accountInfo, uint256 amount) private {
    // Free from escrow in order to consider any expired escrow balance
    require(accountInfo.freedBalance >= amount, "FETH: Insufficient available funds");
    // The require above ensures balance cannot underflow
    unchecked {
      accountInfo.freedBalance -= uint128(amount);
    }
  }

  /**
   * @dev Moves expired escrow to the available balance.
   */
  function _freeFromEscrow(address account) private returns (AccountInfo storage) {
    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance memory escrow = accountInfo.lockups[escrowIndex];

    // If the first bucket is not ready to be freed, no change to escrowStartIndex is required
    if (escrow.expiration == 0) {
      return accountInfo;
    }
    if (escrow.expiration >= block.timestamp) {
      return accountInfo;
    }

    while (true) {
      delete accountInfo.lockups[escrowIndex];

      // Total ETH will not realistically overflow 128 bits
      unchecked {
        accountInfo.freedBalance += escrow.totalAmount;
        escrow = accountInfo.lockups[escrowIndex + 1];
      }

      // If the next bucket is empty, the start index is set to the previous bucket
      if (escrow.expiration == 0) {
        break;
      }

      unchecked {
        // Increment the escrow start index if the next bucket is not empty
        escrowIndex++;
      }

      // If the next bucket is expired, that's the new start index
      if (escrow.expiration >= block.timestamp) {
        break;
      }
    }

    // Escrow index will not realistically overflow 128 bits
    unchecked {
      accountInfo.lockupStartIndex = uint128(escrowIndex);
    }
    return accountInfo;
  }

  /**
   * @dev Removes the specified amount from locked escrow, potentially before its expiration.
   */
  function _removeFromLockedBalance(
    address account,
    uint256 expiration,
    uint256 amount
  ) private returns (AccountInfo storage) {
    require(expiration >= block.timestamp, "FETH: Escrow expired");

    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance storage escrow = accountInfo.lockups[escrowIndex];

    if (escrow.expiration == expiration) {
      // If removing from the first bucket, we may be able to delete it
      if (escrow.totalAmount == amount) {
        delete accountInfo.lockups[escrowIndex];

        // Bump the escrow start index unless it's the last one
        if (accountInfo.lockups[escrowIndex + 1].expiration != 0) {
          // The number of escrow buckets will never overflow 128 bits
          unchecked {
            accountInfo.lockupStartIndex++;
          }
        }
      } else {
        require(escrow.totalAmount >= amount, "FETH: Insufficient escrow");
        // The require above ensures balance will not underflow
        unchecked {
          escrow.totalAmount -= uint128(amount);
        }
      }
    } else {
      // Removing from the 2nd+ bucket
      while (true) {
        // The number of escrow buckets will never overflow 128 bits
        unchecked {
          escrowIndex++;
        }
        escrow = accountInfo.lockups[escrowIndex];
        if (escrow.expiration == expiration) {
          require(escrow.totalAmount >= amount, "FETH: Insufficient escrow");
          // The require above ensures balance will not underflow
          unchecked {
            escrow.totalAmount -= uint128(amount);
          }
          // We may have an entry with 0 totalAmount but expiration will be set
          break;
        }
        require(escrow.expiration != 0, "FETH: Escrow not found");
      }
    }

    emit BalanceUnlocked(account, expiration, amount);
    return accountInfo;
  }

  function _marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) private {
    AccountInfo storage accountInfo = _removeFromLockedBalance(account, expiration, amount);
    // Total ETH cannot realistically overflow 128 bits
    unchecked {
      accountInfo.freedBalance += uint128(amount);
    }
  }

  function _marketDepositFor(address account, uint256 amount) private returns (uint256 expiration) {
    require(account != address(0), "FETH: Cannot deposit for lockup with address 0");
    require(amount > 0, "FETH: Must deposit positive amount");

    // Block timestamp in seconds is small enough to never overflow
    unchecked {
      // Lockup expires after 24 hours, rounded up to the next hour for a total of [24-25) hours
      expiration = lockupDuration + block.timestamp.ceilDiv(lockupInterval) * lockupInterval;
    }

    // Update available escrow
    // Always free from escrow to ensure the max bucket count is <= 25
    AccountInfo storage accountInfo = _freeFromEscrow(account);
    if (msg.value < amount) {
      // The if above prevents underflow with delta, and the require prevents underflow of freed balance
      unchecked {
        uint256 delta = amount - msg.value;
        require(accountInfo.freedBalance >= delta, "FETH: Insufficient available funds");
        accountInfo.freedBalance -= uint128(delta);
      }
    } else {
      require(msg.value == amount, "FETH: Must deposit exact amount");
    }

    // Add to locked escrow
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance storage escrow = accountInfo.lockups[escrowIndex];
        if (escrow.expiration == 0) {
          // Expiration (timestamp) and amount (ETH) will always be < 128 bits
          escrow.expiration = uint128(expiration);
          escrow.totalAmount = uint128(amount);
          break;
        }
        if (escrow.expiration == expiration) {
          // Total ETH will always be < 128 bits
          escrow.totalAmount += uint128(amount);
          break;
        }
      }
    }

    emit BalanceLocked(account, expiration, amount);
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   */
  function totalSupply() external view returns (uint256) {
    /* It is possible for this to diverge from the total token count by transferring ETH on self destruct
       but this is on-par with the WETH implementation and done for gas savings. */
    return address(this).balance;
  }

  /**
   * @notice Returns the amount which a spender is still allowed to withdraw from the owner.
   */
  function allowance(address account, address operator) public view returns (uint256) {
    AccountInfo storage accountInfo = accountToInfo[account];
    return accountInfo.allowance[operator];
  }

  /**
   * @notice Returns the balance of an account, available to transfer or withdraw.
   */
  function balanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 128 bits and escrowIndex will always be < 256 bits
    unchecked {
      // Add expired lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance memory escrow = accountInfo.lockups[escrowIndex];
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the total balance of an account, including locked up funds.
   */
  function totalBalanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 128 bits and escrowIndex will always be < 256 bits
    unchecked {
      // Add all lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance memory escrow = accountInfo.lockups[escrowIndex];
        if (escrow.expiration == 0) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the configuration which is applied when balance is locked.
   */
  function getLockupConfiguration() external view returns (uint256 duration, uint256 interval) {
    return (lockupDuration, lockupInterval);
  }

  /**
   * @notice Returns the balance and each outstanding lockup bucket for an account.
   */
  function getLockups(address account) external view returns (uint256[] memory expiries, uint256[] memory amounts) {
    AccountInfo storage accountInfo = accountToInfo[account];

    // Count lockups
    uint256 lockedCount;
    // The number of buckets is always < 256 bits
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance memory escrow = accountInfo.lockups[escrowIndex];
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount > 0) {
          lockedCount++;
        }
      }
    }

    // Allocate arrays
    expiries = new uint256[](lockedCount);
    amounts = new uint256[](lockedCount);

    // Populate results
    uint256 i;
    // The number of buckets is always < 256 bits
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance memory escrow = accountInfo.lockups[escrowIndex];
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount > 0) {
          expiries[i] = escrow.expiration;
          amounts[i] = escrow.totalAmount;
          i++;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}