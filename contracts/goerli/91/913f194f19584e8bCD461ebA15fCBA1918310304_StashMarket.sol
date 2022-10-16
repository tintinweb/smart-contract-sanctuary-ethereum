// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../shared/NFTTypes.sol";
import "../shared/TokenTransfers.sol";

import "./mixins/StashMarketBuy.sol";
import "./mixins/StashMarketCore.sol";
import "./mixins/StashMarketFees.sol";
import "./mixins/StashMarketLender.sol";
import "./mixins/StashMarketRenter.sol";
import "./mixins/StashMarketTerms.sol";

/**
 * @title The Stash Market for renting and buying NFTs.
 * @author batu-inal & HardlyDifficult
 */
contract StashMarket is
  NFTTypes,
  TokenTransfers,
  StashMarketCore,
  StashMarketFees,
  StashMarketTerms,
  StashMarketLender,
  StashMarketRenter,
  StashMarketBuy
{
  /**
   * @notice Assign immutable variables defined in this proxy's implementation.
   * @param _weth The address of the WETH contract for this network.
   * @param _treasury The address to which payments to Stash should be sent.
   * @param _feeInBasisPoints The fee percentage for the Stash treasury, in basis points.
   */
  constructor(
    address payable _weth,
    address payable _treasury,
    uint16 _feeInBasisPoints
  )
    TokenTransfers(_weth)
    StashMarketFees(_treasury, _feeInBasisPoints) // solhint-disable-next-line no-empty-blocks
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../WrappedNFTs/interfaces/IERC4907.sol";
import "../WrappedNFTs/interfaces/IERC5006.sol";

import "../shared/SharedTypes.sol";

import "../libraries/SupportsInterfaceUnchecked.sol";

/**
 * @title A mixin for checking supported contract interfaces.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTTypes {
  using SupportsInterfaceUnchecked for address;

  /**
   * @notice Reverts if the contract is not a valid ERC-721 NFT.
   * @param requireLending If true, also revert if the NFT does not support ERC-4907.
   */
  modifier onlyERC721(address nftContract, bool requireLending) {
    require(
      nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId),
      "NFTTypes: NFT must support ERC721"
    );
    if (requireLending) {
      // Check required interfaces to list on Stash Market.
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId),
        "NFTTypes: NFT must support ERC4907"
      );
    }
    _;
  }

  /**
   * @notice Reverts if the contract is not a valid ERC-1155 NFT.
   * @param requireLending If true, also revert if the NFT does not support ERC-5006.
   */
  modifier onlyERC1155(address nftContract, bool requireLending) {
    require(
      nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId),
      "NFTTypes: NFT must support ERC1155"
    );

    if (requireLending) {
      // Check required interfaces to list on Stash Market.
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId),
        "NFTTypes: NFT must support ERC5006"
      );
    }

    _;
  }

  /**
   * @notice Checks which type of NFT the given contract is, reverting if neither ERC-721 nor ERC-1155.
   * @param requireLending If true, also revert if the NFT does not support ERC-4907 (for 721) or ERC-5006 (for 1155).
   */
  function _checkNftType(address nftContract, bool requireLending) internal view returns (NFTType nftType) {
    if (nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId)) {
      if (requireLending) {
        // Check required interfaces to list on Stash Market.
        require(
          nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId),
          "NFTTypes: NFT must support ERC4907"
        );
      }

      nftType = NFTType.ERC721;
    } else {
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId),
        "NFTTypes: NFT must support ERC721 or ERC1155"
      );

      if (requireLending) {
        // Check required interfaces to list on Stash Market.
        require(
          nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId),
          "NFTTypes: NFT must support ERC5006"
        );
      }

      nftType = NFTType.ERC1155;
    }
  }

  /**
   * @notice Checks whether a contract is rentable on the Stash Market.
   * @param nftContract The address of the checked contract.
   * @return isCompatible True if the NFT supports the required NFT & lending interfaces.
   */
  function _isCompatibleForRent(address nftContract) internal view returns (bool isCompatible) {
    isCompatible =
      (nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId) &&
        nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId)) ||
      (nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId) &&
        nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId));
  }

  // This is a stateless contract, no upgrade-safe gap required.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IWeth.sol";

import "../shared/Constants.sol";

/**
 * @title Manage transfers of ETH and ERC20 tokens.
 * @dev This is a mixin instead of a library in order to support an immutable variable.
 * @author batu-inal & HardlyDifficult
 */
abstract contract TokenTransfers {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address payable;

  /**
   * @notice The WETH contract address on this network.
   */
  address payable public immutable weth;

  /**
   * @notice Assign immutable variables defined in this proxy's implementation.
   * @param _weth The address of the WETH contract for this network.
   */
  constructor(address payable _weth) {
    require(_weth.isContract(), "TokenTransfers: WETH is not a contract");
    weth = _weth;
  }

  /**
   * @notice Transfer funds from the msg.sender to the recipient specified.
   * @param to The address to which the funds should be sent.
   * @param paymentToken The ERC-20 token to be used for the transfer, or address(0) for ETH.
   * @param amount The amount of funds to be sent.
   * @dev When ETH is used, the caller is required to confirm that the total provided is as expected.
   * Callers should ensure amount != 0 before using this function.
   */
  function _transferFunds(
    address to,
    address paymentToken,
    uint256 amount
  ) internal {
    require(to != address(0), "TokenTransfers: to is required");

    if (paymentToken == address(0)) {
      // ETH
      // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = to.call{ value: amount, gas: SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT }("");
      if (!success) {
        // Store the funds that failed to send for the user in WETH
        IWeth(weth).deposit{ value: amount }();
        IWeth(weth).transfer(to, amount);
      }
    } else {
      // ERC20 Token
      require(msg.value == 0, "TokenTransfers: ETH cannot be sent with a token payment");
      IERC20Upgradeable(paymentToken).safeTransferFrom(msg.sender, to, amount);
    }
  }

  // This is a stateless contract, no upgrade-safe gap required.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title A place for common modifiers and functions used by various market mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketCore {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/Constants.sol";
import "../../shared/TokenTransfers.sol";

/**
 * @title Calculates and distributes Stash market protocol fees.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketFees is TokenTransfers {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapTop;

  /**
   * @notice The address to which payments to Stash should be sent.
   */
  address payable public immutable treasury;

  /**
   * @notice Thee fee percentage to be paid for the Stash treasury, in basis points.
   */
  uint16 public immutable feeInBasisPoints;

  /**
   * @notice Assign immutable variables defined in this proxy's implementation.
   * @param _treasury The address to which payments to Stash should be sent.
   * @param _feeInBasisPoints The fee percentage for the Stash treasury, in basis points.
   */
  constructor(address payable _treasury, uint16 _feeInBasisPoints) {
    require(
      _feeInBasisPoints == 0 ? _treasury == address(0) : _treasury != address(0),
      "StashMarketFees: treasury is required when fees are defined"
    );
    require(_feeInBasisPoints < BASIS_POINTS, "StashMarketFees: Fee basis points cannot be >= 100%");

    treasury = _treasury;
    feeInBasisPoints = _feeInBasisPoints;
  }

  /**
   * @notice Distributes fees to the treasury, from funds provided by the msg.sender.
   * @param paymentToken The ERC-20 token to be used for payment, or address(0) for ETH.
   * @param totalTransactionAmount The total price paid for the current transaction, of which fees will be taken from.
   * @return feeAmount The amount that was sent to the treasury for the protocol fee.
   */
  function _payFees(address paymentToken, uint256 totalTransactionAmount) internal returns (uint256 feeAmount) {
    feeAmount = totalTransactionAmount * feeInBasisPoints;
    unchecked {
      feeAmount /= BASIS_POINTS;
    }

    // Send fees to treasury
    if (feeAmount != 0) {
      _transferFunds(treasury, paymentToken, feeAmount);
    }
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../WrappedNFTs/interfaces/IERC4907.sol";
import "../../WrappedNFTs/interfaces/IERC5006.sol";

import "../../libraries/Time.sol";
import "../../shared/TokenTransfers.sol";

import "./StashMarketFees.sol";
import "./StashMarketTerms.sol";

/**
 * @title Allows collectors to buy an NFT from the Stash market.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketBuy is TokenTransfers, StashMarketFees, StashMarketTerms {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapTop;

  using Time for uint64;

  /**
   * @notice Emitted when an NFT is purchased.
   * @param termsId The id created when the terms from the lender were set.
   * @param buyer The address which purchased the NFT.
   */
  event Bought(uint256 indexed termsId, address indexed buyer);

  /**
   * @notice Buy an NFT which is currently unrented, or rented by the buyer.
   * @param termsId The id created when the terms from the lender were set.
   */
  function buy(uint256 termsId) external payable {
    RentalTerms storage terms = _getRentalTerms(termsId);

    require(!terms.expiry.hasExpired(), "StashMarketBuy: Offer terms have been canceled or have expired");

    uint256 buyPrice = terms.buyPrice;
    require(buyPrice != 0, "StashMarketBuy: Buy price must be set");

    address paymentToken = terms.paymentToken;
    require(paymentToken != address(0) || msg.value == buyPrice, "StashMarketBuy: Incorrect funds provided");

    NFTType nftType = terms.nftType;
    address nftContract = terms.nftContract;
    uint256 tokenId = terms.tokenId;
    address seller = terms.lender;

    // 1155 only fields
    uint64 amount = terms.amount;
    uint256 erc5006RecordId = terms.erc5006RecordId;

    // Delete before other state changes to guard against reentrancy.
    _deleteRentalTerms(termsId);
    // `terms.` cannot be used below.

    // Distribute funds before transfer to minimize risk of reentrancy.
    unchecked {
      // Math is safe since fees are always < amount provided
      buyPrice -= _payFees(paymentToken, buyPrice);
    }
    _transferFunds(seller, paymentToken, buyPrice);

    // Acquire ownership
    if (nftType == NFTType.ERC721) {
      address renter = IERC4907(nftContract).userOf(tokenId);
      if (renter != address(0)) {
        require(renter == msg.sender, "StashMarketBuy: Only the current renter can buy");

        // End the rental agreement first.
        IERC4907(nftContract).setUser(tokenId, address(0), 0);
      }

      // Transfer NFT to the buyer.
      IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);
    } else {
      // 1155

      if (erc5006RecordId != 0) {
        // Check previous record details.
        IERC5006.UserRecord memory userRecord = IERC5006(nftContract).userRecordOf(erc5006RecordId);

        // Expired or canceled records may have been deleted in the NFT contract.
        if (userRecord.amount != 0) {
          // Amount should always be a match, but even if it's not the transfer below will prevent over-withdrawal.

          // If the record has expired, anyone can delete the record and buy the NFT.
          if (!userRecord.expiry.hasExpired()) {
            // If the record has not expired, only the current renter can delete the record and buy the NFT.
            require(userRecord.user == msg.sender, "StashMarketBuy: Only the current renter can buy");
          }

          // End the rental agreement first.
          // 5006 tokens may not automatically remove expired records, if non-zero amount returned assume delete is
          // required even if the record is expired.
          IERC5006(nftContract).deleteUserRecord(erc5006RecordId);
        }
      }

      // Transfer NFT to the buyer.
      IERC1155(nftContract).safeTransferFrom(seller, msg.sender, tokenId, amount, "");
    }

    emit Bought(termsId, msg.sender);
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../libraries/Time.sol";
import "../../shared/NFTTypes.sol";

import "./StashMarketTerms.sol";

/**
 * @title Stash Market functionality for lenders to manage offer terms.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketLender is NFTTypes, StashMarketTerms {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapTop;

  using Time for uint64;

  /**
   * @notice Emitted when a lender cancels rental terms.
   * @param termsId The id created when the terms from the lender were set.
   */
  event RentalTermsCancelled(uint256 indexed termsId);

  /**
   * @notice Cancels rental terms so that they may not be accepted again in the future.
   * @param termsId The id created when the terms from the lender were set.
   */
  function cancelRentalTerms(uint256 termsId) external {
    RentalTerms storage rentalTerms = _getRentalTerms(termsId);
    require(rentalTerms.lender == msg.sender, "StashMarketLender: Must be lender to cancel");
    require(!rentalTerms.expiry.hasExpired(), "StashMarketLender: Cannot cancel expired rental");

    _deleteRentalTerms(termsId);

    emit RentalTermsCancelled(termsId);
  }

  /**
   * @notice Sets terms to rent or buy an ERC-721 NFT.
   * @param nftContract The address of the contract to offer from.
   * @param tokenId The id of the token to offer.
   * @param paymentToken The address of the token to be used for payment, or address(0) for ETH.
   * @param pricePerDay The price per day to rent the NFT.
   * @param buyPrice The price to buy the NFT.
   * @param lenderRevShareInBasisPoints The percent of revenue the lender should receive from play rewards, in basis
   * points.
   * @param maxRentalDays The maximum number of days the NFT can be rented for.
   * @param expiry The time at which the terms will expire.
   */
  function setERC721RentalTerms(
    address nftContract,
    uint256 tokenId,
    address paymentToken,
    uint96 pricePerDay,
    uint96 buyPrice,
    uint16 lenderRevShareInBasisPoints,
    uint16 maxRentalDays,
    uint64 expiry
  ) external onlyERC721(nftContract, true) returns (uint256 termsId) {
    // Confirm the lender's ownership.
    require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "StashMarketLender: Must be ownerOf NFT");

    // Approval is required for someone to be able to to rent or to buy.
    require(
      IERC721(nftContract).isApprovedForAll(msg.sender, address(this)) ||
        IERC721(nftContract).getApproved(tokenId) == address(this),
      "StashMarketLender: NFT must be approved for Market"
    );

    termsId = _setRentalTerms(
      nftContract,
      tokenId,
      1,
      NFTType.ERC721,
      paymentToken,
      pricePerDay,
      buyPrice,
      lenderRevShareInBasisPoints,
      maxRentalDays,
      expiry
    );
  }

  /**
   * @notice Sets terms to rent or buy an ERC-1155 NFT.
   * @param nftContract The address of the contract to offer from.
   * @param tokenId The id of the token to offer.
   * @param amount The amount of the token to offer.
   * @param paymentToken The address of the token to be used for payment, or address(0) for ETH.
   * @param pricePerDay The price per day to rent the NFT.
   * @param buyPrice The price to buy the NFT.
   * @param lenderRevShareInBasisPoints The percent of revenue the lender should receive from play rewards, in basis
   * points.
   * @param maxRentalDays The maximum number of days the NFT can be rented for.
   * @param expiry The time at which the terms will expire.
   */
  function setERC1155RentalTerms(
    address nftContract,
    uint256 tokenId,
    uint64 amount,
    address paymentToken,
    uint96 pricePerDay,
    uint96 buyPrice,
    uint16 lenderRevShareInBasisPoints,
    uint16 maxRentalDays,
    uint64 expiry
  ) external onlyERC1155(nftContract, true) returns (uint256 termsId) {
    require(amount != 0, "StashMarketLender: Cannot set 0 amount");

    // Confirm the lender's ownership.
    require(
      IERC1155(nftContract).balanceOf(msg.sender, tokenId) >= amount,
      "StashMarketLender: Must own at least the amount being offered"
    );

    // Approval is required for someone to be able to to rent or to buy.
    require(
      IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)),
      "StashMarketLender: NFT must be approved for Market"
    );

    termsId = _setRentalTerms(
      nftContract,
      tokenId,
      amount,
      NFTType.ERC1155,
      paymentToken,
      pricePerDay,
      buyPrice,
      lenderRevShareInBasisPoints,
      maxRentalDays,
      expiry
    );
  }

  /**
   * @notice Checks whether a contract is rentable on the Stash Market.
   * @param nftContract The address of the checked contract.
   * @return isCompatible True if the NFT may be listed for rent in this contract.
   */
  function isCompatibleForRent(address nftContract) external view returns (bool isCompatible) {
    isCompatible = _isCompatibleForRent(nftContract);
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../WrappedNFTs/interfaces/IERC5006.sol";
import "../../WrappedNFTs/interfaces/IPlayRewardShare721.sol";
import "../../WrappedNFTs/interfaces/IPlayRewardShare1155.sol";

import "../../libraries/Time.sol";
import "../../shared/SharedTypes.sol";
import "../../shared/TokenTransfers.sol";

import "./StashMarketFees.sol";
import "./StashMarketTerms.sol";

/**
 * @title Stash Market functionality for renting NFTs.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketRenter is TokenTransfers, StashMarketFees, StashMarketTerms {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapTop;

  using SafeCast for uint256;
  using Time for uint64;

  /**
   * @notice Emitted when a user has rented an NFT.
   * @param termsId The id created when the terms from the lender were set.
   * @param renter The address which rented the NFT.
   * @param rentalDays The length of the rental agreement, in days.
   */
  event RentalTermsAccepted(uint256 indexed termsId, address indexed renter, uint256 rentalDays);

  /**
   * @notice Starts a new rental agreement.
   * @param termsId The id created when the terms from the lender were set.
   * @param rentalDays The length of the rental agreement, in days.
   */
  function acceptRentalTerms(uint256 termsId, uint256 rentalDays) external payable {
    require(rentalDays != 0, "StashMarketRenter: Must rent for at least one day");

    RentalTerms storage terms = _getRentalTerms(termsId);
    require(!terms.expiry.hasExpired(), "StashMarketRenter: Rental terms have expired");
    require(rentalDays <= terms.maxRentalDays, "StashMarketRenter: Rental length exceeds max rental length");

    uint64 currentRentalExpiry;
    unchecked {
      // Math is safe since rentalDays is capped by maxRentalDays which is 16 bits.
      currentRentalExpiry = uint64(block.timestamp + rentalDays * 1 days);
    }

    address lender = terms.lender;

    // Distribute funds before creating the rental agreement to minimize risk of reentrancy.
    {
      uint256 amount = terms.pricePerDay;
      if (amount != 0) {
        unchecked {
          // Checked math is not required since pricePerDay is capped to uint96 and rentalDays is capped to uint16.
          amount *= rentalDays;
        }
        address paymentToken = terms.paymentToken;
        require(paymentToken != address(0) || msg.value == amount, "StashMarketRenter: Incorrect funds provided");
        unchecked {
          // Math is safe since fees are always < amount provided
          amount -= _payFees(paymentToken, amount);
        }
        _transferFunds(lender, paymentToken, amount);
      } else {
        require(msg.value == 0, "StashMarketRenter: Incorrect funds provided");
      }
    }

    // Set rental agreement in the NFT contract.
    {
      address nftContract = terms.nftContract;
      uint256 tokenId = terms.tokenId;
      if (terms.nftType == NFTType.ERC721) {
        require(lender == IERC721(nftContract).ownerOf(tokenId), "StashMarketRenter: Lender no longer owns NFT");
        require(IERC4907(nftContract).userOf(tokenId) == address(0), "StashMarketRenter: NFT has already been rented");

        // If approval was lost, the `setUser` call will revert.
        IERC4907(nftContract).setUser(tokenId, msg.sender, currentRentalExpiry);

        // Attempt to set play rewards, however this API is non-standard and not required.
        try
          IPlayRewardShare721(nftContract).setPlayRewardShares(
            tokenId,
            terms.lenderRevShareInBasisPoints,
            treasury,
            feeInBasisPoints
          )
        // solhint-disable-next-line no-empty-blocks
        {
          // Play rewards were set.
        } catch // solhint-disable-next-line no-empty-blocks
        {
          // Failed to set play rewards, ignore the error.
        }
      } else {
        // 1155

        // Clean up the previous rental agreement if there was one and it has expired.
        {
          uint256 originalERC5006RecordId = terms.erc5006RecordId;
          if (originalERC5006RecordId != 0) {
            IERC5006.UserRecord memory userRecord = IERC5006(nftContract).userRecordOf(originalERC5006RecordId);

            // Ignore empty records
            if (userRecord.amount != 0) {
              require(userRecord.expiry.hasExpired(), "StashMarketRenter: NFT has already been rented");

              // End the rental agreement first
              // 5006 tokens may not automatically remove expired records, if non-zero amount returned assume delete is
              // required even if the record is expired.
              IERC5006(nftContract).deleteUserRecord(originalERC5006RecordId);
            }
          }
        }

        // If approval was lost or the NFT was transferred, the `createUserRecord` call will revert.
        uint256 newERC5006RecordId = IERC5006(nftContract).createUserRecord(
          lender,
          msg.sender,
          tokenId,
          terms.amount,
          currentRentalExpiry
        );
        terms.erc5006RecordId = newERC5006RecordId.toUint184();

        // Attempt to set play rewards, however this API is non-standard and not required.
        try
          IPlayRewardShare1155(nftContract).setPlayRewardShares(
            newERC5006RecordId,
            terms.lenderRevShareInBasisPoints,
            treasury,
            feeInBasisPoints
          )
        // solhint-disable-next-line no-empty-blocks
        {
          // Play rewards were set.
        } catch // solhint-disable-next-line no-empty-blocks
        {
          // Failed to set play rewards, ignore the error.
        }
      }
    }

    emit RentalTermsAccepted(termsId, msg.sender, rentalDays);
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../WrappedNFTs/interfaces/IERC4907.sol";

import "../../libraries/Time.sol";
import "../../shared/Constants.sol";
import "../../shared/SharedTypes.sol";

import "./StashMarketFees.sol";

/**
 * @title Stash Market container for rental terms and agreements.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketTerms is StashMarketFees {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapTop;

  using Time for uint64;

  /**
   * @notice A counter to assign a unique sequence ID to each set of terms created.
   */
  uint256 private nextTermsId;

  /**
   * @notice Stores the termsId for a given ERC-721 NFT.
   */
  mapping(address => mapping(uint256 => uint256)) private erc721ContractToTokenIdToTermsId;

  /**
   * @notice Stores terms for renting or buying an NFT, by termsId.
   */
  mapping(uint256 => RentalTerms) private termsIdToRentalTerms;

  /**
   * @notice Emitted when a lender sets rental or purchase terms.
   * @param termsId The id created when the terms from the lender were set.
   * @param nftContract The address of the contract being offered.
   * @param tokenId The id of the token being offered.
   * @param amount The amount of the token being offered, always 1 for ERC-721.
   * @param nftType The type of NFT being offered, 0 for ERC-721 and 1 for ERC-1155.
   * @param lender The address of the lender (or seller).
   * @param paymentToken The address of the token to be used for payment.
   * @param pricePerDay The price per day to rent the NFT.
   * @param buyPrice The price to buy the NFT.
   * @param lenderRevShareInBasisPoints The percent of revenue the lender should receive from play rewards, in basis
   * points.
   * @param maxRentalDays The maximum number of days the NFT can be rented for.
   * @param expiry The time at which these terms will expire.
   */
  event RentalTermsSet(
    uint256 indexed termsId,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 amount,
    NFTType nftType,
    address lender,
    address paymentToken,
    uint256 pricePerDay,
    uint256 buyPrice,
    uint256 lenderRevShareInBasisPoints,
    uint256 maxRentalDays,
    uint256 expiry
  );

  /**
   * @notice Clears stored terms for a given termsId.
   * @dev Callers confirm the terms exist before calling and should emit an event.
   */
  function _deleteRentalTerms(uint256 termsId) internal {
    RentalTerms storage terms = termsIdToRentalTerms[termsId];
    if (terms.nftType == NFTType.ERC721) {
      delete erc721ContractToTokenIdToTermsId[terms.nftContract][terms.tokenId];
    }
    delete termsIdToRentalTerms[termsId];
    // Either cancel or bought events will be emitted.
  }

  /**
   * @notice Assigns new rental terms and returns a unique termsId.
   */
  function _setRentalTerms(
    address nftContract,
    uint256 tokenId,
    uint64 amount,
    NFTType nftType,
    address paymentToken,
    uint96 pricePerDay,
    uint96 buyPrice,
    uint16 lenderRevShareInBasisPoints,
    uint16 maxRentalDays,
    uint64 expiry
  ) internal virtual returns (uint256 termsId) {
    require(!expiry.hasExpired(), "StashMarketTerms: Cannot list expired rental");
    require(
      lenderRevShareInBasisPoints < BASIS_POINTS - feeInBasisPoints,
      "StashMarketLender: Invalid lenderRevShareInBasisPoints"
    );
    require(pricePerDay != 0 || paymentToken == address(0), "StashMarketLender: Free rentals must be in ETH");

    // nextTermsId cannot overflow 256 bits.
    unchecked {
      termsId = ++nextTermsId;
    }

    if (nftType == NFTType.ERC721) {
      uint256 originalTermsId = erc721ContractToTokenIdToTermsId[nftContract][tokenId];
      if (originalTermsId != 0) {
        // Clear previous terms for this NFT if it's a ERC-721
        delete termsIdToRentalTerms[originalTermsId];
      }

      // Store the termsId for this NFT if it's a ERC-721
      erc721ContractToTokenIdToTermsId[nftContract][tokenId] = termsId;
    }

    RentalTerms storage terms = termsIdToRentalTerms[termsId];
    terms.nftContract = nftContract;
    terms.tokenId = tokenId;
    if (nftType == NFTType.ERC1155) {
      // ERC-721 is type 0, save gas by not writing the default value.
      terms.nftType = nftType;
      // Only save amount for 1155 tokens.
      terms.amount = amount;
    }
    terms.expiry = expiry;
    terms.pricePerDay = pricePerDay;
    terms.lenderRevShareInBasisPoints = lenderRevShareInBasisPoints;
    terms.buyPrice = buyPrice;
    terms.lender = msg.sender;
    terms.paymentToken = paymentToken;
    terms.maxRentalDays = maxRentalDays;

    emit RentalTermsSet(
      termsId,
      nftContract,
      tokenId,
      amount,
      nftType,
      msg.sender,
      paymentToken,
      pricePerDay,
      buyPrice,
      lenderRevShareInBasisPoints,
      maxRentalDays,
      expiry
    );
  }

  /**
   * @notice Get the termsId for a given ERC-721 NFT.
   * @param nftContract The address of the ERC-721 contract.
   * @param tokenId The token id of the NFT to check.
   * @return termsId The id of terms for the NFT, or 0 if none was found.
   * @dev This function does not support ERC-1155 NFTs, since those are fungible there may be many terms set.
   */
  function getERC721TermsId(address nftContract, uint256 tokenId) external view returns (uint256 termsId) {
    termsId = erc721ContractToTokenIdToTermsId[nftContract][tokenId];
  }

  /**
   * @notice Gets details about terms for a rental or purchase.
   * @param termsId The id of the terms to retrieve.
   * @return terms Details about the terms.
   */
  function getRentalTerms(uint256 termsId) external view returns (RentalTerms memory terms) {
    if (!termsIdToRentalTerms[termsId].expiry.hasExpired()) {
      terms = termsIdToRentalTerms[termsId];
      if (terms.nftType == NFTType.ERC721) {
        // Return amount 1 for consistency, even though it's not in storage.
        terms.amount = 1;
      }
    }
  }

  /**
   * @notice Returns a storage pointer to terms.
   * @dev Storage may be used in read-only use cases to save gas by limiting SLOADs.
   */
  function _getRentalTerms(uint256 termsId) internal view returns (RentalTerms storage terms) {
    terms = termsIdToRentalTerms[termsId];
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private __gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @notice Supported NFT types.
 */
enum NFTType {
  ERC721,
  ERC1155
}

/**
 * @notice Potential user roles supported by play rewards.
 */
enum RecipientRole {
  Player,
  Owner,
  Operator
}

/**
 * @notice Stores a recipient and their share owed for payments.
 * @param to The address to which payments should be made.
 * @param share The percent share of the payments owed to the recipient, in basis points.
 * @param role The role of the recipient in terms of why they are receiving a share of payments.
 */
struct Recipient {
  address payable to;
  uint16 shareInBasisPoints;
  RecipientRole role;
}

/**
 * @notice Details about an offer to rent or buy an NFT.
 * @param nftContract The address of the NFT contract.
 * @param tokenId The tokenId of the NFT these terms are for.
 * @param nftType The type of NFT this nftContract represents.
 * @param amount The amount of the asset being offered, if ERC-721 this is always 1 (but 0 in storage).
 * @param expiry The timestamp at which this offer expires.
 * @param pricePerDay The price per day of the offer, in wei.
 * @param lenderRevShareInBasisPoints The percent of revenue the lender should receive from play rewards, in basis
 * points. uint16 so that it cannot be set to an unreasonably high value.
 * @param buyPrice The price to buy the NFT outright, in wei -- if 0 then the NFT is not for sale.
 * @param paymentToken The address of the ERC-20 token to use for payments, or address(0) for ETH.
 * @param lender The address of the lender which set these terms.
 * @param maxRentalDays The maximum number of days this NFT can be rented for.
 * @param erc5006RecordId The ERC-5006 recordId of the NFT, if it is an ERC-1155 NFT and has already been rented.
 */
struct RentalTerms {
  // Slot 1
  address nftContract;
  // Capping pricePerDay to 96-bits to allow slot packing.
  uint96 pricePerDay;
  // 0-bits available

  // Slot 2
  uint256 tokenId;
  // Slot 3
  address paymentToken;
  // Capping pricePerDay to 96-bits to allow slot packing.
  uint96 buyPrice;
  // 0-bits available

  // Slot 4
  address lender;
  uint64 expiry;
  uint16 lenderRevShareInBasisPoints;
  uint16 maxRentalDays;
  // 0-bits available

  // Slot 5
  NFTType nftType;
  // Capping recordId to 184-bits to allow for slot packing.
  uint184 erc5006RecordId;
  // `amount` is limited to uint64 in the ERC-5006 spec.
  uint64 amount;
  // 0-bits available
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev From github.com/OpenZeppelin/openzeppelin-contracts/blob/dc4869e
 *           /contracts/utils/introspection/ERC165Checker.sol#L107
 * TODO: Remove once OZ releases this function.
 */
library SupportsInterfaceUnchecked {
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
  function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
    // prepare call
    bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

    // perform static call
    bool success;
    uint256 returnSize;
    uint256 returnValue;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
      returnSize := returndatasize()
      returnValue := mload(0x00)
    }

    return success && returnSize >= 0x20 && returnValue > 0;
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

/**
 * @title Rental NFT, ERC-721 User And Expires Extension
 * @dev Source: https://eips.ethereum.org/EIPS/eip-4907
 * With more elaborate comments added.
 */
interface IERC4907 {
  /**
   * @notice Emitted when the rental terms of an NFT are set or deleted.
   * @param tokenId The NFT which is being rented.
   * @param user The user who is renting the NFT.
   * The zero address for user indicates that there is no longer any active renter of this NFT.
   * @param expiry The time at which the rental expires.
   */
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expiry);

  /**
   * @notice Defines rental terms for an NFT.
   * @param tokenId The NFT which is being rented. Throws if `tokenId` is not valid NFT.
   * @param user The user who is renting the NFT and has access to use it in game.
   * @param expiry The time at which these rental terms expire.
   * @dev Zero for `user` and `expiry` are used to delete the current rental information, which can be done by the
   * operator which set the rental terms.
   */
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expiry
  ) external;

  /**
   * @notice Get the expiry time of the current rental terms for an NFT.
   * @param tokenId The NFT to get the expiry of.
   * @return expiry The time at which the rental terms expire.
   * @dev Zero indicates that there is no longer any active renter of this NFT.
   */
  function userExpires(uint256 tokenId) external view returns (uint256 expiry);

  /**
   * @notice Get the rental user of an NFT.
   * @param tokenId The NFT to get the rental user of.
   * @return user The user which is renting the NFT and has access to use it in game.
   * @dev The zero address indicates that there is no longer any active renter of this NFT.
   */
  function userOf(uint256 tokenId) external view returns (address user);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

/**
 * @title Rental NFT, NFT User Extension
 * @dev Source: https://eips.ethereum.org/EIPS/eip-5006
 * With more elaborate comments added.
 */
interface IERC5006 {
  /**
   * @notice Details about a rental.
   * @param tokenId The NFT which is being rented.
   * @param owner The owner of the NFT which was rented out.
   * @param amount The amount of the NFT which was rented to this user.
   * @param user The user who is renting the NFT.
   * @param expiry The time at which the rental expires.
   */
  struct UserRecord {
    uint256 tokenId;
    address owner;
    uint64 amount;
    address user;
    uint64 expiry;
  }

  /**
   * @notice Emitted when the rental terms of an NFT are set.
   * @param recordId A unique identifier for this rental.
   * @param tokenId The NFT which is being rented.
   * @param amount The amount of the NFT which was rented to this user.
   * @param owner The owner of the NFT which was rented out.
   * @param user The user who is renting the NFT.
   * @param expiry The time at which the rental expires.
   * @dev Emitted when permission for `user` to use `amount` of `tokenId` token owned by `owner`
   * until `expiry` are given.
   * Indexed fields are not used in order to remain consistent with the EIP.
   */
  event CreateUserRecord(uint256 recordId, uint256 tokenId, uint256 amount, address owner, address user, uint64 expiry);

  /**
   * @notice Emitted when the rental terms of an NFT are deleted.
   * @param recordId A unique identifier for the rental which was deleted.
   * @dev Indexed fields are not used in order to remain consistent with the EIP.
   * This event is not emitted for expired records.
   */
  event DeleteUserRecord(uint256 recordId);

  /**
   * @notice Creates rental terms by giving permission to `user` to use `amount` of `tokenId` token owned by `owner`
   * until `expiry`.
   * @param owner The owner of the NFT which is being rented out.
   * @param user The user who is being granted rights to use this NFT for a period of time.
   * @param tokenId The NFT which is being rented.
   * @param amount The amount of the NFT which is being rented to this user.
   * @param expiry The time at which the rental expires.
   * @return recordId A unique identifier for this rental.
   * @dev Emits a {CreateUserRecord} event.
   *
   * Requirements:
   *
   * - If the caller is not `owner`, it must be have been approved to spend ``owner``'s tokens
   * via {setApprovalForAll}.
   * - `owner` must have a balance of tokens of type `id` of at least `amount`.
   * - `user` cannot be the zero address.
   * - `amount` must be greater than 0.
   * - `expiry` must after the block timestamp.
   */
  function createUserRecord(
    address owner,
    address user,
    uint256 tokenId,
    uint64 amount,
    uint64 expiry
  ) external returns (uint256 recordId);

  /**
   * @notice Deletes previously assigned rental terms.
   * @param recordId The identifier of the rental terms to delete.
   */
  function deleteUserRecord(uint256 recordId) external;

  /**
   * @notice Return the total amount of a given token that this owner account has rented out.
   * @param account The owner of the NFT which is being rented out.
   * @param tokenId The NFT which is being rented.
   * @return amount The total amount of the NFT which is being rented out.
   * @dev Expired or deleted records are not included in the total.
   */
  function frozenBalanceOf(address account, uint256 tokenId) external view returns (uint256 amount);

  /**
   * @notice Return the total amount of a given token that this user account has rented.
   * @param account The user who is renting the NFT.
   * @param tokenId The NFT which is being rented.
   * @return amount The total amount of the NFT which is being rented to this user.
   * @dev This may include rentals for this user from multiple NFT owners.
   * Expired or deleted records are not included in the total.
   */
  function usableBalanceOf(address account, uint256 tokenId) external view returns (uint256 amount);

  /**
   * @notice Returns the rental terms for a given record identifier.
   * @param recordId The identifier of the rental terms to return.
   * @return record The rental terms for the given record identifier.
   * @dev Expired or deleted records are not returned.
   */
  function userRecordOf(uint256 recordId) external view returns (UserRecord memory record);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
pragma solidity ^0.8.12;

interface IWeth {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @dev 100% in basis points.
 */
uint16 constant BASIS_POINTS = 10_000;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

/**
 * @dev The percent of revenue the NFT owner should receive from play reward payments generated while this NFT is
 * rented, in basis points.
 */
uint16 constant DEFAULT_OWNER_REWARD_SHARE_IN_BASIS_POINTS = 1_000; // 10%

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Helpers for working with time.
 * @author batu-inal & HardlyDifficult
 */
library Time {
  /**
   * @notice Checks if the given timestamp is in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   */
  function hasExpired(uint64 expiry) internal view returns (bool) {
    return expiry < block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/SharedTypes.sol";

/**
 * @title APIs for play rewards generated by this ERC-1155 NFT.
 * @author batu-inal & HardlyDifficult
 */
interface IPlayRewardShare1155 {
  /**
   * @notice Emitted when play rewards are paid through this contract.
   * @param tokenId The tokenId of the NFT for which rewards were paid.
   * @param to The address to which the rewards were paid.
   * There may be multiple payments for a single payment transaction, one for each recipient.
   * @param operator The account which initiated and provided the funds for this payment.
   * @param amount The amount of NFTs used to generate the rewards.
   * @param recordId The associated rental recordId, or 0 if n/a.
   * @param role The role of the recipient in terms of why they are receiving a share of payments.
   * @param paymentToken The token used to pay the rewards, or address(0) if ETH was distributed.
   * @param tokenAmount The amount of `paymentToken` sent to the `to` address.
   */
  event PlayRewardPaid(
    uint256 indexed tokenId,
    address indexed to,
    address indexed operator,
    uint256 amount,
    uint256 recordId,
    RecipientRole role,
    address paymentToken,
    uint256 tokenAmount
  );

  /**
   * @notice Emitted when additional recipients are provided for an NFT's play rewards.
   * @param recordId The recordId of the NFT rental for which reward recipients were set.
   * @param ownerRevShareInBasisPoints The share of rewards to be paid to the owner of this NFT.
   * @param operatorRevShareInBasisPoints The share of rewards to be paid to the operator of this NFT.
   */
  event PlayRewardRecipientsSet(
    uint256 indexed recordId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  );

  /**
   * @notice Pays play rewards generated by this NFT to the expected recipients.
   * @param tokenId The tokenId of the NFT for which rewards were earned.
   * @param amount The amount of NFTs used to generate the rewards.
   * @param recordId The associated rental recordId, or 0 if n/a.
   * @param recipients The address and relative share each recipient should receive.
   * @param paymentToken The token to use to pay the rewards, or address(0) if ETH will be distributed.
   * @param tokenAmount The amount of `paymentToken` to distribute to the recipients.
   * @dev If an ERC-20 token is used for payment, the `msg.sender` should first grant approval to this contract.
   */
  function payPlayRewards(
    uint256 tokenId,
    uint256 amount,
    uint256 recordId,
    Recipient[] calldata recipients,
    address paymentToken,
    uint256 tokenAmount
  ) external payable;

  /**
   * @notice Sets additional recipients for play rewards generated by this NFT.
   * @dev This is only callable while rented, by the operator which created the rental.
   * @param recordId The recordId of the NFT for which reward recipients should be set.
   * @param ownerRevShareInBasisPoints The share of rewards to be paid to the owner of this NFT.
   * @param operatorRevShareInBasisPoints The share of rewards to be paid to the operator of this NFT.
   * The user/player of the NFT will automatically be added as a recipient, receiving the remaining share - the sum
   * provided for the additional recipients must be less than 100%.
   */
  function setPlayRewardShares(
    uint256 recordId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  ) external;

  /**
   * @notice Gets the expected recipients for play rewards generated by this NFT.
   * @return recipients The addresses to which rewards should be paid and their relative shares.
   * @dev If the record is found, this will return 1 or more recipients, and the shares defined will sum to exactly 100%
   * in basis points. If the record is not found, this will revert instead.
   */
  function getPlayRewardShares(uint256 recordId) external view returns (Recipient[] memory recipients);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/SharedTypes.sol";

/**
 * @title APIs for play rewards generated by this ERC-721 NFT.
 * @author batu-inal & HardlyDifficult
 */
interface IPlayRewardShare721 {
  /**
   * @notice Emitted when play rewards are paid through this contract.
   * @param tokenId The tokenId of the NFT for which rewards were paid.
   * @param to The address to which the rewards were paid.
   * There may be multiple payments for a single payment transaction, one for each recipient.
   * @param operator The account which initiated and provided the funds for this payment.
   * @param role The role of the recipient in terms of why they are receiving a share of payments.
   * @param paymentToken The token used to pay the rewards, or address(0) if ETH was distributed.
   * @param tokenAmount The amount of `paymentToken` sent to the `to` address.
   */
  event PlayRewardPaid(
    uint256 indexed tokenId,
    address indexed to,
    address indexed operator,
    RecipientRole role,
    address paymentToken,
    uint256 tokenAmount
  );

  /**
   * @notice Emitted when additional recipients are provided for an NFT's play rewards.
   * @param tokenId The tokenId of the NFT for which reward recipients were set.
   * @param ownerRevShareInBasisPoints The share of rewards to be paid to the owner of this NFT.
   * @param operatorRevShareInBasisPoints The share of rewards to be paid to the operator of this NFT.
   */
  event PlayRewardRecipientsSet(
    uint256 indexed tokenId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  );

  /**
   * @notice Pays play rewards generated by this NFT to the expected recipients.
   * @param tokenId The tokenId of the NFT for which rewards were earned.
   * @param recipients The address and relative share each recipient should receive.
   * @param paymentToken The token to use to pay the rewards, or address(0) if ETH will be distributed.
   * @param tokenAmount The amount of `paymentToken` to distribute to the recipients.
   * @dev If an ERC-20 token is used for payment, the `msg.sender` should first grant approval to this contract.
   */
  function payPlayRewards(
    uint256 tokenId,
    Recipient[] calldata recipients,
    address paymentToken,
    uint256 tokenAmount
  ) external payable;

  /**
   * @notice Sets additional recipients for play rewards generated by this NFT.
   * @dev This is only callable while rented, by the operator which created the rental.
   * @param tokenId The tokenId of the NFT for which reward recipients should be set.
   * @param ownerRevShareInBasisPoints The share of rewards to be paid to the owner of this NFT.
   * @param operatorRevShareInBasisPoints The share of rewards to be paid to the operator of this NFT.
   * The user/player of the NFT will automatically be added as a recipient, receiving the remaining share - the sum
   * provided for the additional recipients must be less than 100%.
   */
  function setPlayRewardShares(
    uint256 tokenId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  ) external;

  /**
   * @notice Gets the expected recipients for play rewards generated by this NFT.
   * @param tokenId The tokenId of the NFT to get recipients for.s
   * @return recipients The addresses to which rewards should be paid and their relative shares.
   * @dev This will return 1 or more recipients, and the shares defined will sum to exactly 100% in basis points.
   */
  function getPlayRewardShares(uint256 tokenId) external view returns (Recipient[] memory recipients);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/Market/StashMarket.sol";

contract $StashMarket is StashMarket {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeInBasisPoints) StashMarket(_weth, _treasury, _feeInBasisPoints) {}

    function $_deleteRentalTerms(uint256 termsId) external {
        return super._deleteRentalTerms(termsId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,uint64 amount,NFTType nftType,address paymentToken,uint96 pricePerDay,uint96 buyPrice,uint16 lenderRevShareInBasisPoints,uint16 maxRentalDays,uint64 expiry) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,amount,nftType,paymentToken,pricePerDay,buyPrice,lenderRevShareInBasisPoints,maxRentalDays,expiry);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_getRentalTerms(uint256 termsId) external view returns (RentalTerms memory) {
        return super._getRentalTerms(termsId);
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketBuy.sol";

contract $StashMarketBuy is StashMarketBuy {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeInBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeInBasisPoints) {}

    function $_deleteRentalTerms(uint256 termsId) external {
        return super._deleteRentalTerms(termsId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,uint64 amount,NFTType nftType,address paymentToken,uint96 pricePerDay,uint96 buyPrice,uint16 lenderRevShareInBasisPoints,uint16 maxRentalDays,uint64 expiry) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,amount,nftType,paymentToken,pricePerDay,buyPrice,lenderRevShareInBasisPoints,maxRentalDays,expiry);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_getRentalTerms(uint256 termsId) external view returns (RentalTerms memory) {
        return super._getRentalTerms(termsId);
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketCore.sol";

contract $StashMarketCore is StashMarketCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketFees.sol";

contract $StashMarketFees is StashMarketFees {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeInBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeInBasisPoints) {}

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketLender.sol";

contract $StashMarketLender is StashMarketLender {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeInBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeInBasisPoints) {}

    function $_deleteRentalTerms(uint256 termsId) external {
        return super._deleteRentalTerms(termsId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,uint64 amount,NFTType nftType,address paymentToken,uint96 pricePerDay,uint96 buyPrice,uint16 lenderRevShareInBasisPoints,uint16 maxRentalDays,uint64 expiry) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,amount,nftType,paymentToken,pricePerDay,buyPrice,lenderRevShareInBasisPoints,maxRentalDays,expiry);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_getRentalTerms(uint256 termsId) external view returns (RentalTerms memory) {
        return super._getRentalTerms(termsId);
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketRenter.sol";

contract $StashMarketRenter is StashMarketRenter {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeInBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeInBasisPoints) {}

    function $_deleteRentalTerms(uint256 termsId) external {
        return super._deleteRentalTerms(termsId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,uint64 amount,NFTType nftType,address paymentToken,uint96 pricePerDay,uint96 buyPrice,uint16 lenderRevShareInBasisPoints,uint16 maxRentalDays,uint64 expiry) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,amount,nftType,paymentToken,pricePerDay,buyPrice,lenderRevShareInBasisPoints,maxRentalDays,expiry);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_getRentalTerms(uint256 termsId) external view returns (RentalTerms memory) {
        return super._getRentalTerms(termsId);
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketTerms.sol";

contract $StashMarketTerms is StashMarketTerms {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeInBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeInBasisPoints) {}

    function $_deleteRentalTerms(uint256 termsId) external {
        return super._deleteRentalTerms(termsId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,uint64 amount,NFTType nftType,address paymentToken,uint96 pricePerDay,uint96 buyPrice,uint16 lenderRevShareInBasisPoints,uint16 maxRentalDays,uint64 expiry) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,amount,nftType,paymentToken,pricePerDay,buyPrice,lenderRevShareInBasisPoints,maxRentalDays,expiry);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_getRentalTerms(uint256 termsId) external view returns (RentalTerms memory) {
        return super._getRentalTerms(termsId);
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IERC4907.sol";

abstract contract $IERC4907 is IERC4907 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IERC5006.sol";

abstract contract $IERC5006 is IERC5006 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IPlayRewardShare1155.sol";

abstract contract $IPlayRewardShare1155 is IPlayRewardShare1155 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IPlayRewardShare721.sol";

abstract contract $IPlayRewardShare721 is IPlayRewardShare721 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IWeth.sol";

abstract contract $IWeth is IWeth {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/SupportsInterfaceUnchecked.sol";

contract $SupportsInterfaceUnchecked {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $supportsERC165InterfaceUnchecked(address account,bytes4 interfaceId) external view returns (bool) {
        return SupportsInterfaceUnchecked.supportsERC165InterfaceUnchecked(account,interfaceId);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/Time.sol";

contract $Time {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $hasExpired(uint64 expiry) external view returns (bool) {
        return Time.hasExpired(expiry);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/Constants.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/NFTTypes.sol";

contract $NFTTypes is NFTTypes {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/SharedTypes.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/TokenTransfers.sol";

contract $TokenTransfers is TokenTransfers {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _weth) TokenTransfers(_weth) {}

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    receive() external payable {}
}