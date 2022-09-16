// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IStashMarket.sol";

import "./mixins/StashMarketBuy.sol";
import "./mixins/StashMarketCore.sol";
import "./mixins/StashMarketFees.sol";
import "./mixins/StashMarketLender.sol";
import "./mixins/StashMarketRenter.sol";
import "./mixins/StashMarketTerms.sol";

/**
 * @author batu-inal & HardlyDifficult
 */
contract StashMarket is
  IStashMarket,
  ERC165,
  StashMarketCore,
  StashMarketFees,
  StashMarketTerms,
  StashMarketRenter,
  StashMarketBuy,
  StashMarketLender
{
  constructor(
    address payable weth,
    address payable treasury,
    uint16 feeBasisPoints
  ) TokenTransfers(weth) StashMarketFees(treasury, feeBasisPoints) {
    _disableInitializers();
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool supported) {
    supported = interfaceId == type(IStashMarket).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IStashMarket.sol";
import "../../WrappedNFTs/interfaces/IERC4907.sol";
import "../../WrappedNFTs/interfaces/IERC5006.sol";

import "../../shared/TokenTransfers.sol";

import "./StashMarketFees.sol";
import "./StashMarketTerms.sol";

/**
 * @title Stash Market functionality for renters.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketBuy is IStashMarket, TokenTransfers, StashMarketFees, StashMarketTerms {
  function buy(uint256 rentalId) external payable {
    RentalTerms memory terms = getRentalTerms(rentalId);
    require(terms.buyPrice != 0, "Buy price must be set");
    require(terms.paymentToken != address(0) || msg.value == terms.buyPrice, "Incorrect funds provided");
    // Can this person buy the NFT at this point in time?
    // has `this` rental expired?
    require(terms.expiry >= block.timestamp, "Buy price expired");

    _acquireOwnership(terms.nftType, terms.nftContract, terms.tokenId, terms.amount, terms.seller, terms.recordId);

    // send funds
    uint256 amount = terms.buyPrice;
    amount -= _payFees(terms.paymentToken, amount);
    _transferFunds(terms.paymentToken, msg.sender, terms.seller, amount);

    emit Bought(rentalId, msg.sender);
  }

  function _acquireOwnership(
    NFTType nftType,
    address nftContract,
    uint256 tokenId,
    uint64 amount,
    address seller,
    uint256 recordId1155 // Not used for NFTType.ERC721.
  ) internal {
    if (nftType == NFTType.ERC721) {
      address renter = IERC4907(nftContract).userOf(tokenId);
      require(renter == address(0) || renter == msg.sender, "Must be renting the NFT");

      // Transfer NFT
      IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);
    } else {
      // 1155
      if (recordId1155 != 0) {
        require(IERC5006(nftContract).usableBalanceOf(msg.sender, tokenId) == amount, "Must be renting the NFT");
        IERC5006(nftContract).deleteUserRecord(recordId1155);
      }

      // Transfer NFT
      // TODO: support user defined amount (maybe it must match how much they had rented)
      IERC1155(nftContract).safeTransferFrom(seller, msg.sender, tokenId, amount, "");
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/Constants.sol";

import "../../shared/TokenTransfers.sol";

/**
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketFees is TokenTransfers {
  address payable public immutable treasury;
  uint16 public immutable feeBasisPoints;

  constructor(address payable _treasury, uint16 _feeBasisPoints) {
    require(
      _feeBasisPoints == 0 ? _treasury == address(0) : _treasury != address(0),
      "StashMarketFees: treasury is required when fees are defined"
    );
    require(_feeBasisPoints <= BASIS_POINTS, "StashMarketFees: fee basis points cannot be greater than 100%");

    treasury = _treasury;
    feeBasisPoints = _feeBasisPoints;
  }

  function _payFees(address paymentToken, uint256 totalTransactionAmount) internal returns (uint256 feeAmount) {
    feeAmount = (totalTransactionAmount * feeBasisPoints) / BASIS_POINTS;

    // Send fees to treasury
    _transferFunds(paymentToken, msg.sender, treasury, feeAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/SharedTypes.sol";

struct RentalTerms {
  address nftContract;
  uint256 tokenId;
  NFTType nftType;
  uint64 amount;
  uint256 expiry;
  uint256 pricePerDay;
  uint256 lenderRevShareBasisPoints;
  uint256 buyPrice;
  address paymentToken;
  address seller;
  // uint16 so that this cannot be set to an unreasonably high value
  uint16 maxRentalDays;
  uint256 recordId;
}

/**
 * @title Stash Market APIs.
 * @author batu-inal & HardlyDifficult
 */
interface IStashMarket {
  event Bought(uint256 indexed rentalId, address indexed buyer);
  event RentalTermsAccepted(uint256 indexed rentalId, address indexed renter, uint256 rentalDays);
  event RentalTermsCancelled(uint256 indexed rentalId);
  event RentalTermsSet(
    uint256 indexed rentalId,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 amount,
    NFTType nftType,
    address lender,
    uint256 expiry,
    uint256 pricePerDay,
    uint256 lenderRevShareBasisPoints,
    uint256 buyPrice,
    address paymentToken,
    uint256 maxRentalDays
  );

  function acceptRentalTerms(uint256 rentalId, uint256 rentalDays) external payable;

  function buy(uint256 rentalId) external payable;

  function cancelRentalTerms(uint256 rentalId) external;

  function setRentalTerms(
    address nftContract,
    uint256 tokenId,
    uint64 amount,
    uint256 expiry,
    uint256 pricePerDay,
    uint256 lenderRevShareBasisPoints,
    uint256 buyPrice,
    address paymentToken,
    uint16 maxRentalDays
  ) external returns (uint256 rentalId);

  function getRentalTerms(uint256 rentalId) external view returns (RentalTerms memory terms);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IStashMarket.sol";
import "../../WrappedNFTs/interfaces/IERC5006.sol";

import "../../shared/TokenTransfers.sol";

import "./StashMarketCore.sol";
import "./StashMarketFees.sol";
import "./StashMarketTerms.sol";

/**
 * @title Stash Market functionality for renters.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketRenter is
  IStashMarket,
  TokenTransfers,
  ERC165,
  StashMarketCore,
  StashMarketFees,
  StashMarketTerms
{
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapTop;

  function acceptRentalTerms(uint256 rentalId, uint256 rentalDays) external payable {
    require(rentalDays != 0, "Must rent for at least one day");
    RentalTerms memory terms = getRentalTerms(rentalId);
    require(terms.expiry > block.timestamp, "Rental terms have expired");
    require(rentalDays <= terms.maxRentalDays, "Rental length exceeds max rental length");

    unchecked {
      // Math is safe since rentalDays is capped by maxRentalDays which is 16 bits.
      uint64 expiry = uint64(block.timestamp + 60 * 60 * 24 * rentalDays);
      _lend(terms.nftType, terms.nftContract, terms.tokenId, terms.amount, terms.seller, expiry, rentalId);

      if (terms.pricePerDay > 0) {
        uint256 amount = terms.pricePerDay * rentalDays;
        require(terms.paymentToken != address(0) || msg.value == amount, "Incorrect funds provided");
        // Math is safe since fees are always < amount provided
        amount -= _payFees(terms.paymentToken, amount);
        _transferFunds(terms.paymentToken, msg.sender, terms.seller, amount);
      } else {
        require(msg.value == 0, "Incorrect funds provided");
      }
    }

    emit RentalTermsAccepted(rentalId, msg.sender, rentalDays);
  }

  function _lend(
    NFTType nftType,
    address nftContract,
    uint256 tokenId,
    uint64 amount,
    address seller,
    uint64 expiry,
    uint256 rentalId
  ) internal {
    if (nftType == NFTType.ERC721) {
      require(
        // lender must still be owner
        seller == IERC721(nftContract).ownerOf(tokenId) &&
          // nft should not be rented out
          IERC4907(nftContract).userOf(tokenId) == address(0),
        "NFT unavailable for rent"
      );
      IERC4907(nftContract).setUser(tokenId, msg.sender, expiry);
    } else {
      // 1155
      require(
        // lender must still own enough amount
        // TODO switch so that the renter can choose a different amount
        // TODO: can we lean on createUserRecord to handle this requirement?
        IERC1155(nftContract).balanceOf(seller, tokenId) - IERC5006(nftContract).frozenBalanceOf(seller, tokenId) >=
          amount,
        "NFT unavailable for rent"
      );
      _getMutableRentalTerms(rentalId).recordId = IERC5006(nftContract).createUserRecord(
        seller,
        msg.sender,
        tokenId,
        amount,
        expiry
      );
    }
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../../libraries/SupportsInterfaceUnchecked.sol";

import "../../WrappedNFTs/interfaces/IERC4907.sol";
import "../../WrappedNFTs/interfaces/IERC5006.sol";
import "../../WrappedNFTs/interfaces/IP2ERoyalties.sol";

/**
 * @title A place for common modifiers and functions used by various market mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketCore {
  using ERC165Checker for address;
  using SupportsInterfaceUnchecked for address;

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;

  /**
   * @notice Checks whether a contract is rentable on the Stash Market.
   * @param nftContract The address of the checked contract.
   */
  function isCompatibleForRent(address nftContract) external view returns (bool isCompatible) {
    isCompatible =
      nftContract.supportsInterface(type(IP2ERoyalties).interfaceId) &&
      ((nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId) &&
        nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId)) ||
        (nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId) &&
          nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IStashMarket.sol";
import "../../WrappedNFTs/interfaces/IERC4907.sol";

/**
 * @title Stash Market container for rental terms and agreements.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketTerms is IStashMarket, Initializable {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapTop;

  /**
   * @notice A global id for rentals.
   */
  uint256 private nextRentalId;

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToRentalId;

  mapping(uint256 => RentalTerms) private rentalIdToRentalTerms;

  /**
   * @notice Returns id to assign to the next rental.
   */
  function _getNextAndIncrementRentalId() internal returns (uint256 id) {
    // rentalId cannot overflow 256 bits.
    unchecked {
      id = ++nextRentalId;
    }
  }

  function getRentalId(address nftContract, uint256 tokenId) external view returns (uint256 rentalId) {
    rentalId = nftContractToTokenIdToRentalId[nftContract][tokenId];
  }

  function getRentalTerms(uint256 rentalId) public view returns (RentalTerms memory terms) {
    terms = rentalIdToRentalTerms[rentalId];
    if (terms.nftType == NFTType.ERC721) {
      // Return amount 1 for consistency, even though it's not in storage.
      terms.amount = 1;
    }
  }

  function expireCurrentRentalTerms(address nftContract, uint256 tokenId) internal {
    uint256 rentalId = nftContractToTokenIdToRentalId[nftContract][tokenId];
    if (rentalId != 0) {
      RentalTerms storage terms = rentalIdToRentalTerms[rentalId];
      // if not expired
      if (terms.expiry > block.timestamp) {
        uint256 rentalExpiry = IERC4907(nftContract).userExpires(tokenId);
        terms.expiry = rentalExpiry > block.timestamp ? rentalExpiry : block.timestamp;
      }
    }
  }

  function _getMutableRentalTerms(uint256 rentalId) internal view returns (RentalTerms storage terms) {
    terms = rentalIdToRentalTerms[rentalId];
  }

  function _setRentalTerms(
    address nftContract,
    uint256 tokenId,
    NFTType nftType,
    uint64 amount,
    uint256 expiry,
    uint256 pricePerDay,
    uint256 lenderRevShareBasisPoints,
    uint256 buyPrice,
    address paymentToken,
    uint16 maxRentalDays
  ) internal virtual returns (uint256 rentalId) {
    expireCurrentRentalTerms(nftContract, tokenId);

    rentalId = _getNextAndIncrementRentalId();
    nftContractToTokenIdToRentalId[nftContract][tokenId] = rentalId;

    RentalTerms storage terms = rentalIdToRentalTerms[rentalId];
    terms.nftContract = nftContract;
    terms.tokenId = tokenId;
    terms.nftType = nftType;
    if (nftType == NFTType.ERC721) {
      // Amount must be inputted as 1 for clarity.
      require(amount == 1, "ERC721 amount must be 1");
      // Don't actually store the amount in order to save gas.
    } else {
      // Only save amount for 1155 tokens.
      terms.amount = amount;
    }
    terms.expiry = expiry;
    terms.pricePerDay = pricePerDay;
    terms.lenderRevShareBasisPoints = lenderRevShareBasisPoints;
    terms.buyPrice = buyPrice;
    terms.seller = msg.sender;
    terms.paymentToken = paymentToken;
    terms.maxRentalDays = maxRentalDays;

    emit RentalTermsSet(
      rentalId,
      nftContract,
      tokenId,
      uint256(amount),
      nftType,
      msg.sender,
      expiry,
      pricePerDay,
      lenderRevShareBasisPoints,
      buyPrice,
      paymentToken,
      uint256(maxRentalDays)
    );
  }

  function _cancelRentalTerms(uint256 rentalId) internal {
    delete rentalIdToRentalTerms[rentalId];
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapBottom;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../interfaces/IStashMarket.sol";
import "../../WrappedNFTs/interfaces/IERC4907.sol";
import "../../WrappedNFTs/interfaces/IERC5006.sol";
import "../../WrappedNFTs/interfaces/IP2ERoyalties.sol";

import "../../libraries/SupportsInterfaceUnchecked.sol";
import "../../libraries/NFTTypes.sol";

import "./StashMarketCore.sol";
import "./StashMarketTerms.sol";

/**
 * @title Stash Market functionality for lenders.
 * @author batu-inal & HardlyDifficult
 */
abstract contract StashMarketLender is IStashMarket, ERC165, StashMarketCore, StashMarketTerms {
  using ERC165Checker for address;
  using SupportsInterfaceUnchecked for address;
  using NFTTypes for address;

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapTop;

  function cancelRentalTerms(uint256 rentalId) external {
    RentalTerms memory rentalTerms = getRentalTerms(rentalId);
    require(rentalTerms.seller == msg.sender, "Must be seller to cancel");
    require(rentalTerms.expiry > block.timestamp, "Cannot cancel expired rental");
    _cancelRentalTerms(rentalId);
    emit RentalTermsCancelled(rentalId);
  }

  function setRentalTerms(
    address nftContract,
    uint256 tokenId,
    uint64 amount,
    uint256 expiry,
    uint256 pricePerDay,
    uint256 lenderRevShareBasisPoints,
    uint256 buyPrice,
    address paymentToken,
    uint16 maxRentalDays
  ) external returns (uint256 rentalId) {
    require(nftContract.supportsERC165(), "NFT contract does not support ERC165");
    NFTType nftType = nftContract.checkNftType(true);
    if (nftType == NFTType.ERC721) {
      // Check eligibility to list.
      require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Must be ownerOf NFT");
      // Approval is required in order to rent or to buy.
      require(
        IERC721(nftContract).isApprovedForAll(msg.sender, address(this)) ||
          IERC721(nftContract).getApproved(tokenId) == address(this),
        "NFT must be approved for Market"
      );

      rentalId = _setRentalTerms(
        nftContract,
        tokenId,
        NFTType.ERC721,
        amount,
        expiry,
        pricePerDay,
        lenderRevShareBasisPoints,
        buyPrice,
        paymentToken,
        maxRentalDays
      );
    } else {
      // 1155
      // Check eligibility to list.
      // TODO: should usableBalanceOf handle non-rented quantities as well? Does that violate the standard?
      require(
        IERC1155(nftContract).balanceOf(msg.sender, tokenId) -
          IERC5006(nftContract).frozenBalanceOf(msg.sender, tokenId) >=
          amount,
        "Must own at least the amount to be lent"
      );
      // TODO support direct approvals?
      // TODO: approval only required if there's a buy price?
      require(IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved for Market");

      rentalId = _setRentalTerms(
        nftContract,
        tokenId,
        NFTType.ERC1155,
        amount,
        expiry,
        pricePerDay,
        lenderRevShareBasisPoints,
        buyPrice,
        paymentToken,
        maxRentalDays
      );
    }
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapBottom;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IWeth.sol";

import "../shared/Constants.sol";

/**
 * @dev This is a mixin instead of a library in order to support an immutable variable.
 * @title Manage transfers of ETH and ERC20 tokens.
 * @author batu-inal & HardlyDifficult
 */
abstract contract TokenTransfers {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address payable;

  address payable private immutable weth;

  constructor(address payable _weth) {
    require(_weth.isContract(), "WETH is not a contract");
    weth = _weth;
  }

  function _transferFunds(
    address paymentToken,
    address from,
    address to,
    uint256 amount
  ) internal {
    // TODO: require amount != 0 and push checks up a level or keep if?
    if (amount == 0) {
      return;
    }

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
      require(msg.value == 0, "Incorrect funds provided");
      IERC20Upgradeable(paymentToken).safeTransferFrom(from, to, amount);
    }
  }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.12;

/**
 * @title Rental NFT, ERC-721 User And Expires Extension
 * @dev Source: https://eips.ethereum.org/EIPS/eip-4907
 */
interface IERC4907 {
  // Logged when the user of an NFT is changed or expires is changed
  /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
  /// The zero address for user indicates that there is no user address
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

  /// @notice set the user and expires of an NFT
  /// @dev The zero address indicates there is no user
  /// Throws if `tokenId` is not valid NFT
  /// @param user  The new user of the NFT
  /// @param expires  UNIX timestamp, The new user could use the NFT before expires
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) external;

  /// @notice Get the user address of an NFT
  /// @dev The zero address indicates that there is no user or the user is expired
  /// @param tokenId The NFT to get the user address for
  /// @return The user address for this NFT
  function userOf(uint256 tokenId) external view returns (address);

  /// @notice Get the user expires of an NFT
  /// @dev The zero value indicates that there is no user
  /// @param tokenId The NFT to get the user expires for
  /// @return The user expires for this NFT
  function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.12;

/**
 * @title Rental NFT, NFT User Extension
 * @dev Source: https://eips.ethereum.org/EIPS/eip-5006
 */
/* is IERC165 */
interface IERC5006 {
  struct UserRecord {
    uint256 tokenId;
    address owner;
    uint64 amount;
    address user;
    uint64 expiry;
  }

  /**
   * @dev Emitted when permission for `user` to use `amount` of `tokenId` token owned by `owner`
   * until `expiry` are given.
   */
  event CreateUserRecord(uint256 recordId, uint256 tokenId, uint256 amount, address owner, address user, uint64 expiry);

  /**
   * @dev Emitted when record of `recordId` are deleted.
   */
  event DeleteUserRecord(uint256 recordId);

  /**
   * @dev Returns the usable amount of `tokenId` tokens  by `account`.
   */
  function usableBalanceOf(address account, uint256 tokenId) external view returns (uint256);

  /**
   * @dev Returns the amount of frozen tokens of token type `id` by `account`.
   */
  function frozenBalanceOf(address account, uint256 tokenId) external view returns (uint256);

  /**
   * @dev Returns the `UserRecord` of `recordId`.
   */
  function userRecordOf(uint256 recordId) external view returns (UserRecord memory);

  /**
   * @dev Gives permission to `user` to use `amount` of `tokenId` token owned by `owner` until `expiry`.
   *
   * Emits a {CreateUserRecord} event.
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
  ) external returns (uint256);

  /**
   * @dev Atomically delete `record` of `recordId` by the caller.
   *
   * Emits a {DeleteUserRecord} event.
   *
   * Requirements:
   *
   * - the caller must have allowance.
   */
  function deleteUserRecord(uint256 recordId) external;
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
pragma solidity ^0.8.12;

interface IWeth {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

uint16 constant BASIS_POINTS = 10_000;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

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

enum NFTType {
  ERC721,
  ERC1155
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Royalty definitions for play to earn revenue.
 * @author batu-inal & HardlyDifficult
 */
interface IP2ERoyalties {
  event P2ERoyaltyPaid(
    uint256 indexed tokenId,
    address indexed player,
    address indexed to,
    address owner,
    address operator,
    address paymentToken,
    uint256 amount
  );

  struct Recipient {
    address recipient;
    uint16 shareInBasisPoints;
  }

  function getP2ERecipients(address player, address owner) external view returns (Recipient[] memory recipients);

  function payP2ERoyalties(
    uint256 tokenId,
    address player,
    address owner,
    address paymentToken,
    uint256 amount
  ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../WrappedNFTs/interfaces/IERC4907.sol";
import "../WrappedNFTs/interfaces/IERC5006.sol";
import "../WrappedNFTs/interfaces/IP2ERoyalties.sol";

import "../shared/SharedTypes.sol";

import "./SupportsInterfaceUnchecked.sol";

/**
 * @author batu-inal & HardlyDifficult
 */
library NFTTypes {
  using SupportsInterfaceUnchecked for address;

  function checkNftType(address nftContract, bool requireLendingAndP2E) internal view returns (NFTType nftType) {
    // TODO: put a top-level 165 check here? Or skip the top-level check all together?

    if (nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId)) {
      if (requireLendingAndP2E) {
        // Check required interfaces to list on Stash Market.
        require(nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId), "NFT must support ERC4907");
      }

      nftType = NFTType.ERC721;
    } else {
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId),
        "NFT must support ERC721 or ERC1155"
      );

      if (requireLendingAndP2E) {
        // Check required interfaces to list on Stash Market.
        require(nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId), "NFT must support ERC5006");
      }

      nftType = NFTType.ERC1155;
    }

    if (requireLendingAndP2E) {
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IP2ERoyalties).interfaceId),
        "NFT must support P2ERoyalties"
      );
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/Market/StashMarket.sol";

contract $StashMarket is StashMarket {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementRentalId_Returned(uint256 arg0);

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable weth, address payable treasury, uint16 feeBasisPoints) StashMarket(weth, treasury, feeBasisPoints) {}

    function $_acquireOwnership(NFTType nftType,address nftContract,uint256 tokenId,uint64 amount,address seller,uint256 recordId1155) external {
        return super._acquireOwnership(nftType,nftContract,tokenId,amount,seller,recordId1155);
    }

    function $_lend(NFTType nftType,address nftContract,uint256 tokenId,uint64 amount,address seller,uint64 expiry,uint256 rentalId) external {
        return super._lend(nftType,nftContract,tokenId,amount,seller,expiry,rentalId);
    }

    function $_getNextAndIncrementRentalId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementRentalId();
        emit $_getNextAndIncrementRentalId_Returned(ret0);
        return (ret0);
    }

    function $expireCurrentRentalTerms(address nftContract,uint256 tokenId) external {
        return super.expireCurrentRentalTerms(nftContract,tokenId);
    }

    function $_getMutableRentalTerms(uint256 rentalId) external view returns (RentalTerms memory) {
        return super._getMutableRentalTerms(rentalId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,NFTType nftType,uint64 amount,uint256 expiry,uint256 pricePerDay,uint256 lenderRevShareBasisPoints,uint256 buyPrice,address paymentToken,uint16 maxRentalDays) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,nftType,amount,expiry,pricePerDay,lenderRevShareBasisPoints,buyPrice,paymentToken,maxRentalDays);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_cancelRentalTerms(uint256 rentalId) external {
        return super._cancelRentalTerms(rentalId);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address paymentToken,address from,address to,uint256 amount) external {
        return super._transferFunds(paymentToken,from,to,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/interfaces/IStashMarket.sol";

abstract contract $IStashMarket is IStashMarket {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketBuy.sol";

abstract contract $StashMarketBuy is StashMarketBuy {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementRentalId_Returned(uint256 arg0);

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeBasisPoints) {}

    function $_acquireOwnership(NFTType nftType,address nftContract,uint256 tokenId,uint64 amount,address seller,uint256 recordId1155) external {
        return super._acquireOwnership(nftType,nftContract,tokenId,amount,seller,recordId1155);
    }

    function $_getNextAndIncrementRentalId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementRentalId();
        emit $_getNextAndIncrementRentalId_Returned(ret0);
        return (ret0);
    }

    function $expireCurrentRentalTerms(address nftContract,uint256 tokenId) external {
        return super.expireCurrentRentalTerms(nftContract,tokenId);
    }

    function $_getMutableRentalTerms(uint256 rentalId) external view returns (RentalTerms memory) {
        return super._getMutableRentalTerms(rentalId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,NFTType nftType,uint64 amount,uint256 expiry,uint256 pricePerDay,uint256 lenderRevShareBasisPoints,uint256 buyPrice,address paymentToken,uint16 maxRentalDays) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,nftType,amount,expiry,pricePerDay,lenderRevShareBasisPoints,buyPrice,paymentToken,maxRentalDays);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_cancelRentalTerms(uint256 rentalId) external {
        return super._cancelRentalTerms(rentalId);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address paymentToken,address from,address to,uint256 amount) external {
        return super._transferFunds(paymentToken,from,to,amount);
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

    constructor(address payable _weth, address payable _treasury, uint16 _feeBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeBasisPoints) {}

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address paymentToken,address from,address to,uint256 amount) external {
        return super._transferFunds(paymentToken,from,to,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketLender.sol";

abstract contract $StashMarketLender is StashMarketLender {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementRentalId_Returned(uint256 arg0);

    event $_setRentalTerms_Returned(uint256 arg0);

    constructor() {}

    function $_getNextAndIncrementRentalId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementRentalId();
        emit $_getNextAndIncrementRentalId_Returned(ret0);
        return (ret0);
    }

    function $expireCurrentRentalTerms(address nftContract,uint256 tokenId) external {
        return super.expireCurrentRentalTerms(nftContract,tokenId);
    }

    function $_getMutableRentalTerms(uint256 rentalId) external view returns (RentalTerms memory) {
        return super._getMutableRentalTerms(rentalId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,NFTType nftType,uint64 amount,uint256 expiry,uint256 pricePerDay,uint256 lenderRevShareBasisPoints,uint256 buyPrice,address paymentToken,uint16 maxRentalDays) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,nftType,amount,expiry,pricePerDay,lenderRevShareBasisPoints,buyPrice,paymentToken,maxRentalDays);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_cancelRentalTerms(uint256 rentalId) external {
        return super._cancelRentalTerms(rentalId);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketRenter.sol";

abstract contract $StashMarketRenter is StashMarketRenter {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementRentalId_Returned(uint256 arg0);

    event $_setRentalTerms_Returned(uint256 arg0);

    event $_payFees_Returned(uint256 arg0);

    constructor(address payable _weth, address payable _treasury, uint16 _feeBasisPoints) TokenTransfers(_weth) StashMarketFees(_treasury, _feeBasisPoints) {}

    function $_lend(NFTType nftType,address nftContract,uint256 tokenId,uint64 amount,address seller,uint64 expiry,uint256 rentalId) external {
        return super._lend(nftType,nftContract,tokenId,amount,seller,expiry,rentalId);
    }

    function $_getNextAndIncrementRentalId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementRentalId();
        emit $_getNextAndIncrementRentalId_Returned(ret0);
        return (ret0);
    }

    function $expireCurrentRentalTerms(address nftContract,uint256 tokenId) external {
        return super.expireCurrentRentalTerms(nftContract,tokenId);
    }

    function $_getMutableRentalTerms(uint256 rentalId) external view returns (RentalTerms memory) {
        return super._getMutableRentalTerms(rentalId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,NFTType nftType,uint64 amount,uint256 expiry,uint256 pricePerDay,uint256 lenderRevShareBasisPoints,uint256 buyPrice,address paymentToken,uint16 maxRentalDays) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,nftType,amount,expiry,pricePerDay,lenderRevShareBasisPoints,buyPrice,paymentToken,maxRentalDays);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_cancelRentalTerms(uint256 rentalId) external {
        return super._cancelRentalTerms(rentalId);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_payFees(address paymentToken,uint256 totalTransactionAmount) external returns (uint256) {
        (uint256 ret0) = super._payFees(paymentToken,totalTransactionAmount);
        emit $_payFees_Returned(ret0);
        return (ret0);
    }

    function $_transferFunds(address paymentToken,address from,address to,uint256 amount) external {
        return super._transferFunds(paymentToken,from,to,amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/Market/mixins/StashMarketTerms.sol";

abstract contract $StashMarketTerms is StashMarketTerms {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementRentalId_Returned(uint256 arg0);

    event $_setRentalTerms_Returned(uint256 arg0);

    constructor() {}

    function $_getNextAndIncrementRentalId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementRentalId();
        emit $_getNextAndIncrementRentalId_Returned(ret0);
        return (ret0);
    }

    function $expireCurrentRentalTerms(address nftContract,uint256 tokenId) external {
        return super.expireCurrentRentalTerms(nftContract,tokenId);
    }

    function $_getMutableRentalTerms(uint256 rentalId) external view returns (RentalTerms memory) {
        return super._getMutableRentalTerms(rentalId);
    }

    function $_setRentalTerms(address nftContract,uint256 tokenId,NFTType nftType,uint64 amount,uint256 expiry,uint256 pricePerDay,uint256 lenderRevShareBasisPoints,uint256 buyPrice,address paymentToken,uint16 maxRentalDays) external returns (uint256) {
        (uint256 ret0) = super._setRentalTerms(nftContract,tokenId,nftType,amount,expiry,pricePerDay,lenderRevShareBasisPoints,buyPrice,paymentToken,maxRentalDays);
        emit $_setRentalTerms_Returned(ret0);
        return (ret0);
    }

    function $_cancelRentalTerms(uint256 rentalId) external {
        return super._cancelRentalTerms(rentalId);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
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

import "../../../contracts/WrappedNFTs/interfaces/IP2ERoyalties.sol";

abstract contract $IP2ERoyalties is IP2ERoyalties {
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

import "../../contracts/libraries/NFTTypes.sol";

contract $NFTTypes {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $checkNftType(address nftContract,bool requireLendingAndP2E) external view returns (NFTType) {
        return NFTTypes.checkNftType(nftContract,requireLendingAndP2E);
    }

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

import "../../contracts/shared/Constants.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/SharedTypes.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/TokenTransfers.sol";

contract $TokenTransfers is TokenTransfers {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _weth) TokenTransfers(_weth) {}

    function $_transferFunds(address paymentToken,address from,address to,uint256 amount) external {
        return super._transferFunds(paymentToken,from,to,amount);
    }

    receive() external payable {}
}