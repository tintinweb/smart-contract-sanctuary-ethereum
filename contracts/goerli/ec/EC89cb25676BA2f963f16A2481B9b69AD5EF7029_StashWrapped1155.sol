// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IERC5006.sol";
import "./interfaces/IStashWrapped1155Factory.sol";
import "./interfaces/IPlayRewardShare1155.sol";

import "../libraries/SupportsInterfaceUnchecked.sol";

import "../shared/TokenTransfers.sol";
import "./mixins/ContractFactory.sol";
import "./mixins/ERC5006.sol";
import "./mixins/PlayRewardShare.sol";
import "./mixins/PlayRewardShare1155.sol";
import "./mixins/WrappedNFT.sol";

/**
 * @title A wrapped version of a single unit of an ERC-1155 NFT contract to enable rentals.
 * @author batu-inal & HardlyDifficult
 */
contract StashWrapped1155 is
  IERC5006,
  IStashWrapped1155Factory,
  IPlayRewardShare1155,
  IERC165,
  ERC165,
  TokenTransfers,
  ContractFactory,
  IERC1155,
  IERC1155MetadataURI,
  ERC1155,
  IERC1155Receiver,
  ERC1155Receiver,
  WrappedNFT,
  ERC5006,
  PlayRewardShare,
  PlayRewardShare1155
{
  using SupportsInterfaceUnchecked for address;

  /**
   * @notice Assign immutable variables defined in this proxy's implementation.
   * @param _weth The address of the WETH contract for this network.
   * @param _contractFactory The address of the contract factory that will create instances of this contract.
   * @dev This will disable initializers in the implementation contract to avoid confusion with proxies themselves.
   */
  constructor(address payable _weth, address _contractFactory)
    TokenTransfers(_weth)
    ContractFactory(_contractFactory)
    ERC1155("") // No URI required for the template contract.
  // solhint-disable-next-line no-empty-blocks
  {
    // initialize is not required for proxy instances since the only instance data required is defined via immutable
    // proxy args. ERC1155's uri is overridden below.
  }

  /**
   * @inheritdoc IStashWrapped1155Factory
   */
  function factoryWrap(
    address owner,
    uint256 id,
    uint256 amount
  ) external onlyContractFactory {
    _wrap(owner, id, amount);
  }

  /**
   * @inheritdoc IStashWrapped1155Factory
   */
  function factoryWrapAndSetApprovalForAll(
    address owner,
    uint256 id,
    uint256 amount,
    address operator
  ) external onlyContractFactory {
    _wrap(owner, id, amount);
    _setApprovalForAll(owner, operator);
  }

  /**
   * @notice Wrap a specific NFT id and amount to enable rentals.
   * @param id The id of the NFT to wrap.
   * @param amount The amount of the NFT to wrap.
   * @dev This function is only callable by the owner of the original NFT.
   */
  function wrap(uint256 id, uint256 amount) external {
    _wrap(msg.sender, id, amount);
  }

  /**
   * @notice Wrap a specific NFT id and amount to enable rentals and grant approval for all on this wrapped contract for
   * the `msg.sender` (NFT owner) and the `operator` provided.
   * @param id The id of the NFT to wrap.
   * @param amount The amount of the NFT to wrap.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This function is only callable by the owner of the original NFT.
   */
  function wrapAndSetApprovalForAll(
    uint256 id,
    uint256 amount,
    address operator
  ) external {
    _wrap(msg.sender, id, amount);
    _setApprovalForAll(msg.sender, operator);
  }

  /**
   * @notice Unwrap a specific NFT tokenId and transfer the original NFT to the `msg.sender`.
   * @param id The id of the NFT to unwrap.
   * @param amount The amount of the NFT to unwrap.
   * @dev The caller must own at least the given amount of the wrapped NFT `id` provided.
   * Any amount current rented out may not be unwrapped.
   */
  function unwrap(uint256 id, uint256 amount) external {
    // Burn will revert if the msg.sender does not own sufficient unrented amount for this `id`.
    _burn(msg.sender, id, amount);

    IERC1155(originalNFTContract()).safeTransferFrom(address(this), msg.sender, id, amount, "");
  }

  /**
   * @notice Called anytime an NFT is minted, transferred, or burned.
   * @dev This instance is a no-op, here to prevent compile errors due to the inheritance used.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC5006) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function _deleteUserRecord(uint32 recordId) internal override(ERC5006, PlayRewardShare1155) {
    super._deleteUserRecord(recordId);
  }

  /**
   * @notice Escrows the given amount of the original NFT and mints a wrapped version with the same amount.
   */
  function _wrap(
    address owner,
    uint256 id,
    uint256 amount
  ) internal {
    require(amount != 0, "StashWrapped1155: Cannot wrap 0 amount");
    _mint(owner, id, amount, "");
    IERC1155(originalNFTContract()).safeTransferFrom(owner, address(this), id, amount, "");
  }

  /**
   * @notice Grants approval for all on this wrapped contract for the NFT owner and the `operator` provided.
   */
  function _setApprovalForAll(address owner, address operator) private {
    require(operator != address(0), "StashWrapped1155: Operator cannot be zero address");
    _setApprovalForAll(owner, operator, true);
  }

  /**
   * @notice Accept transfers which where originated from this contract.
   */
  function onERC1155Received(
    address operator,
    address, /* from */
    uint256, /* id */
    uint256, /* value */
    bytes calldata /* data */
  ) external view returns (bytes4) {
    require(operator == address(this), "StashWrapped1155: Transfers must be initiated by this contract");
    return IERC1155Receiver.onERC1155Received.selector;
  }

  /**
   * @notice Deny all batch transfers to this contract.
   */
  function onERC1155BatchReceived(
    address, /* operator */
    address, /* from */
    uint256[] calldata, /* ids */
    uint256[] calldata, /* values */
    bytes calldata /* data */
  ) external pure returns (bytes4) {
    revert("StashWrapped1155: Batch transfers are not accepted");
  }

  /**
   * @notice Checks if this contract implements the given ERC-165 interface.
   * @param interfaceId The interface to check for.
   * @return supported True if this contract implements the given interface.
   * @dev This instance is a no-op, here to prevent compile errors due to the inheritance used.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165, ERC165, ERC1155, ERC1155Receiver, ERC5006, PlayRewardShare1155)
    returns (bool supported)
  {
    supported = super.supportsInterface(interfaceId);
  }

  /**
   * @notice The URI for a specific NFT.
   * @param id The id of the NFT to get the URI for.
   * @dev Returns the URI from the original NFT contract.
   */
  function uri(uint256 id) public view virtual override(IERC1155MetadataURI, ERC1155) returns (string memory) {
    return IERC1155MetadataURI(originalNFTContract()).uri(id);
  }
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
pragma solidity ^0.8.12;

/**
 * @title Factory interface for ERC-1155 wrapped NFTs.
 * @author batu-inal & HardlyDifficult
 */
interface IStashWrapped1155Factory {
  /**
   * @notice Wrap a specific NFT id and amount to enable rentals.
   * @param owner The account that currently owns the original NFT.
   * @param id The id of the NFT to wrap.
   * @param amount The amount of the NFT to wrap.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrap(
    address owner,
    uint256 id,
    uint256 amount
  ) external;

  /**
   * @notice Wrap a specific NFT id and amount to enable rentals and grant approval for all on this wrapped contract for
   * the NFT owner and the `operator` provided.
   * @param owner The account that currently owns the original NFT.
   * @param id The id of the NFT to wrap.
   * @param amount The amount of the NFT to wrap.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrapAndSetApprovalForAll(
    address owner,
    uint256 id,
    uint256 amount,
    address operator
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Stores a reference to the factory which is used to create contract proxies.
 * @author batu-inal & HardlyDifficult
 */
abstract contract ContractFactory {
  using Address for address;

  /**
   * @notice The address of the factory which was used to create this contract.
   * @return The factory contract address.
   */
  address public immutable contractFactory;

  /**
   * @notice Requires the msg.sender is the same address that was used to create this proxy contract.
   */
  modifier onlyContractFactory() {
    require(msg.sender == contractFactory, "ContractFactory: Caller is not the factory");
    _;
  }

  /**
   * @notice Assign immutable variables defined in this proxy's implementation.
   * @param _contractFactory The factory which will be used to create these proxy contracts.
   */
  constructor(address _contractFactory) {
    require(_contractFactory.isContract(), "ContractFactory: Factory is not a contract");
    contractFactory = _contractFactory;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/IERC5006.sol";

import "../../libraries/ArrayLibrary.sol";
import "../../libraries/Time.sol";

/**
 * @title Rental implementation for ERC-1155.
 * @dev Modified from https://eips.ethereum.org/EIPS/eip-5006 reference impl
 * @author batu-inal & HardlyDifficult
 */
abstract contract ERC5006 is IERC5006, ERC1155 {
  using ArrayLibrary for uint32[];
  using Time for uint64;
  using SafeCast for uint256;

  /**
   * @notice Stores details about a rental, by record ID.
   */
  mapping(uint256 => UserRecord) private recordIdToUserRecord;

  /**
   * @notice Stores the address which created the record, if an account other than the current NFT owner.
   */
  mapping(uint256 => address) private recordIdToOperator;

  /**
   * @notice Stores all the active records for an NFT created by a an owner of that NFT.
   */
  mapping(uint256 => mapping(address => uint32[])) private tokenIdToOwnerToRecordIdSet;

  /**
   * @notice Stores all the active records for an NFT for the renter of that NFT.
   */
  mapping(uint256 => mapping(address => uint32[])) private tokenIdToUserToRecordIdSet;

  /**
   * @notice Tracks the last used recordId so that each record has a unique sequence ID assigned.
   */
  uint256 private currentRecordId;

  /**
   * @notice Caps the number of active rentals a user or owner may have for a given tokenId.
   * @dev This is required in order to ensure the loops below do not create an unbounded gas cost.
   * 64 is arbitrary, balancing between flexibility and worst case gas costs.
   */
  uint256 private constant RECORD_LIMIT = 64;

  /**
   * @notice Emitted when rental terms are set by a user other than the NFT owner.
   * @param recordId The ID for the rental record created.
   * @param operator The `msg.sender` which initiated the rental.
   * @dev The operator has permission to cancel a rental.
   */
  event UserRecordOperatorSet(uint256 recordId, address operator);

  /**
   * @inheritdoc IERC5006
   */
  function createUserRecord(
    address owner,
    address user,
    uint256 tokenId,
    uint64 amount,
    uint64 expiry
  ) external returns (uint256 recordId) {
    require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "ERC5006: Only owner or approved");
    require(user != address(0), "ERC5006: user cannot be the zero address");
    require(amount != 0, "ERC5006: amount must be greater than 0");
    require(!expiry.hasExpired(), "ERC5006: expiry must be after the block timestamp");

    // Cap the max number of active records per owner & user.
    uint256 frozen = _freeExpiredBalanceForOwner(owner, tokenId);
    require(
      tokenIdToOwnerToRecordIdSet[tokenId][owner].length < RECORD_LIMIT,
      "ERC5006: owner cannot have more records"
    );
    _freeExpiredBalanceForUser(user, tokenId);
    require(tokenIdToUserToRecordIdSet[tokenId][user].length < RECORD_LIMIT, "ERC5006: user cannot have more records");

    // Ensure that the owner has sufficient supply available to rent.
    unchecked {
      // Safe math is not required because the amount of outstanding rentals cannot exceed the owner's balance.
      require(
        balanceOf(owner, tokenId) - frozen >= amount,
        "ERC5006: owner must have a balance of tokens of at least amount"
      );
    }

    // Store the new record.
    unchecked {
      // recordId cannot overflow 256-bits
      recordId = ++currentRecordId;
    }
    recordIdToUserRecord[recordId] = UserRecord(tokenId, owner, amount, user, expiry);

    // Store the recordId for both the user and owner.
    // SafeCast is not necessary if we are confident there will not be > 4bil records created.
    uint32 recordId32 = recordId.toUint32();
    tokenIdToOwnerToRecordIdSet[tokenId][owner].push() = recordId32;
    tokenIdToUserToRecordIdSet[tokenId][user].push() = recordId32;

    // Emit the record details.
    emit CreateUserRecord(recordId, tokenId, amount, owner, user, expiry);

    // Store and emit the operator only if it is not the current owner.
    if (owner != msg.sender) {
      recordIdToOperator[recordId] = msg.sender;
      emit UserRecordOperatorSet(recordId, msg.sender);
    }
  }

  /**
   * @inheritdoc IERC5006
   * @dev Can only be called by the account which created the record.
   * This is inconsistent with the EIP-5006 standard, but done so that operators can make guarantees.
   */
  function deleteUserRecord(uint256 recordId) external {
    UserRecord storage record = recordIdToUserRecord[recordId];
    bool hasExpired = record.expiry.hasExpired();

    // Anyone can delete an expired record.
    if (!hasExpired) {
      address operator = recordIdToOperator[recordId];

      // Validate permission to delete.
      require(
        operator == msg.sender || (operator == address(0) && record.owner == msg.sender) || record.user == msg.sender,
        "ERC5006: Only the operator or renter can delete the record"
      );
    }

    // SafeCast is not required since creation prevents inserting > uint32 into the recordIdToOperator mapping and an
    // empty entry would fail the require above.
    _deleteUserRecord(uint32(recordId));

    // The delete event is only emitted when deleting unexpired records.
    if (!hasExpired) {
      emit DeleteUserRecord(recordId);
    }
  }

  /**
   * @notice Called anytime an NFT is minted, transferred, or burned.
   * @dev This instance will block transfers anytime there is insufficient available balance due to active rentals.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    // When wrapping new tokens (from == address(0)), active rental balance is not relevant.
    if (from != address(0)) {
      for (uint256 i = 0; i < ids.length; ) {
        uint256 tokenId = ids[i];
        // Remove any expired entries for the owner and confirm there is sufficient available balance.
        uint256 frozen = _freeExpiredBalanceForOwner(from, tokenId);
        require(balanceOf(from, tokenId) - frozen >= amounts[i], "ERC5006: Insufficient available balance");

        unchecked {
          ++i;
        }
      }
    }
  }

  /**
   * @notice Clears storage for a given recordId.
   */
  function _deleteUserRecord(uint32 recordId) internal virtual {
    UserRecord storage record = recordIdToUserRecord[recordId];
    tokenIdToOwnerToRecordIdSet[record.tokenId][record.owner].remove(recordId);
    tokenIdToUserToRecordIdSet[record.tokenId][record.user].remove(recordId);
    delete recordIdToUserRecord[recordId];
    delete recordIdToOperator[recordId];
  }

  /**
   * @notice Removes any expired records for the owner, and sums the amount current rented out for a given NFT.
   */
  function _freeExpiredBalanceForOwner(address owner, uint256 tokenId) private returns (uint256 frozenBalance) {
    uint32[] storage recordIds = tokenIdToOwnerToRecordIdSet[tokenId][owner];
    unchecked {
      uint256 length = recordIds.length;
      for (uint256 i = 0; i < length; ) {
        if (recordIdToUserRecord[recordIds[i]].expiry.hasExpired()) {
          _deleteUserRecord(recordIds[i]);

          // When popping a record, decrease the length and do not increment i.
          --length;
        } else {
          // The total amount rented out cannot exceed 256 bits.
          frozenBalance += recordIdToUserRecord[recordIds[i]].amount;
          // Only increment if we did not pop a record, so that no entries are missed.
          ++i;
        }
      }
    }
  }

  /**
   * @notice Removes any expired records for a user of a given NFT.
   */
  function _freeExpiredBalanceForUser(address user, uint256 tokenId) private {
    uint32[] storage recordIds = tokenIdToUserToRecordIdSet[tokenId][user];
    uint256 length = recordIds.length;
    for (uint256 i = 0; i < length; ) {
      if (recordIdToUserRecord[recordIds[i]].expiry.hasExpired()) {
        _deleteUserRecord(recordIds[i]);

        // When popping a record, decrease the length and do not increment i.
        --length;
      } else {
        // Only increment if we did not pop a record, so that no entries are missed.
        unchecked {
          ++i;
        }
      }
    }
  }

  /**
   * @inheritdoc IERC5006
   */
  function frozenBalanceOf(address account, uint256 tokenId) external view returns (uint256 amount) {
    uint32[] storage recordIds = tokenIdToOwnerToRecordIdSet[tokenId][account];
    unchecked {
      uint256 length = recordIds.length;
      for (uint256 i = 0; i < length; ++i) {
        if (!recordIdToUserRecord[recordIds[i]].expiry.hasExpired()) {
          // The total amount rented out cannot exceed 256 bits.
          amount += recordIdToUserRecord[recordIds[i]].amount;
        }
      }
    }
  }

  /**
   * @notice Returns the operator with permissions to delete a given recordId.
   * @param recordId The recordId to query.
   * @return operator The operator with permissions to delete the record.
   */
  function recordOperatorOf(uint256 recordId) public view returns (address operator) {
    UserRecord storage record = recordIdToUserRecord[recordId];

    // Only return if the record is not yet expired
    if (!record.expiry.hasExpired()) {
      operator = recordIdToOperator[recordId];
      if (operator == address(0)) {
        // If the operator is not assigned in storage, it's assumed the owner created the record.
        operator = record.owner;
      }
    }
  }

  /**
   * @notice Checks if this contract implements the given ERC-165 interface.
   * @param interfaceId The interface to check for.
   * @return supported True if this contract implements the given interface.
   * @dev This instance checks the ERC-5006 interface.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool supported) {
    supported = interfaceId == type(IERC5006).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC5006
   */
  function usableBalanceOf(address account, uint256 tokenId) external view returns (uint256 amount) {
    uint32[] storage recordIds = tokenIdToUserToRecordIdSet[tokenId][account];
    unchecked {
      uint256 length = recordIds.length;
      for (uint256 i = 0; i < length; ++i) {
        if (!recordIdToUserRecord[recordIds[i]].expiry.hasExpired()) {
          // The total amount rented by a user cannot exceed 256 bits.
          amount += recordIdToUserRecord[recordIds[i]].amount;
        }
      }
    }
  }

  /**
   * @inheritdoc IERC5006
   */
  function userRecordOf(uint256 recordId) public view returns (UserRecord memory record) {
    record = recordIdToUserRecord[recordId];
    if (record.expiry.hasExpired()) {
      // If expired, return an empty object instead.
      record = UserRecord(0, address(0), 0, address(0), 0);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IPlayRewardShare1155.sol";
import "../interfaces/IERC5006.sol";

import "../../shared/Constants.sol";
import "../../shared/TokenTransfers.sol";

import "./ERC5006.sol";
import "./PlayRewardShare.sol";
import "./ERC5006.sol";

/**
 * @title APIs for play rewards generated by this ERC-1155 NFT.
 * @author batu-inal & HardlyDifficult
 */
abstract contract PlayRewardShare1155 is
  IERC5006,
  IPlayRewardShare1155,
  ERC165,
  TokenTransfers,
  ERC5006,
  PlayRewardShare
{
  /**
   * @inheritdoc IPlayRewardShare1155
   */
  function payPlayRewards(
    uint256 tokenId,
    uint256 amount,
    uint256 recordId,
    Recipient[] calldata recipients,
    address paymentToken,
    uint256 tokenAmount
  ) external payable validTokenAmount(paymentToken, tokenAmount) requireRecipients(recipients) {
    uint256 totalDistributed;
    uint256 length = recipients.length;
    for (uint256 i = 1; i < length; ) {
      uint256 toDistribute = (tokenAmount * recipients[i].shareInBasisPoints) / BASIS_POINTS;
      totalDistributed += toDistribute;
      _payReward(tokenId, amount, recordId, recipients[i], paymentToken, toDistribute);

      unchecked {
        ++i;
      }
    }

    // Round in favor of the first recipient
    _payReward(tokenId, amount, recordId, recipients[0], paymentToken, tokenAmount - totalDistributed);
  }

  /**
   * @inheritdoc IPlayRewardShare1155
   */
  function setPlayRewardShares(
    uint256 recordId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  ) external {
    require(recordOperatorOf(recordId) == msg.sender, "PlayRewardShare1155: Only the operator can set recipients");
    _setPlayRewardShares(recordId, ownerRevShareInBasisPoints, operatorRecipient, operatorRevShareInBasisPoints);
    emit PlayRewardRecipientsSet(
      recordId,
      ownerRevShareInBasisPoints,
      operatorRecipient,
      operatorRevShareInBasisPoints
    );
  }

  /**
   * @inheritdoc ERC5006
   * @dev Anytime the rental terms are cleared, also clear recorded play reward recipients. They can be reset by the
   * operator when applicable.
   */
  function _deleteUserRecord(uint32 recordId) internal virtual override {
    _deletePlayRewards(recordId);
    super._deleteUserRecord(recordId);
  }

  /**
   * @notice Distributes play reward payments to the given recipient, if the amount is greater than 0.
   */
  function _payReward(
    uint256 tokenId,
    uint256 amount,
    uint256 recordId,
    Recipient calldata recipient,
    address paymentToken,
    uint256 tokenAmount
  ) private {
    if (tokenAmount != 0) {
      _transferFunds(recipient.to, paymentToken, tokenAmount);
      emit PlayRewardPaid({
        tokenId: tokenId,
        to: recipient.to,
        operator: msg.sender,
        amount: amount,
        recordId: recordId,
        role: recipient.role,
        paymentToken: paymentToken,
        tokenAmount: tokenAmount
      });
    }
  }

  /**
   * @inheritdoc IPlayRewardShare1155
   */
  function getPlayRewardShares(uint256 recordId) external view returns (Recipient[] memory recipients) {
    UserRecord memory record = userRecordOf(recordId);
    require(record.expiry != 0, "PlayRewardShare1155: Record does not exist");
    recipients = _getPlayRewardShares(recordId, record.user, record.owner);
  }

  /**
   * @notice Checks if this contract implements the given ERC-165 interface.
   * @param interfaceId The interface to check for.
   * @return supported True if this contract implements the given interface.
   * @dev This instance checks the IPlayRewardShare1155 interface.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, ERC5006)
    returns (bool supported)
  {
    supported = interfaceId == type(IPlayRewardShare1155).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IPlayRewardShare721.sol";

import "../../shared/Constants.sol";
import "../../shared/TokenTransfers.sol";

/**
 * @title Shared logic for play reward shares.
 * @author batu-inal & HardlyDifficult
 */
abstract contract PlayRewardShare {
  struct RewardShares {
    // `isSet` ensures that explicitly assigning 0/0 cannot be changed.
    bool isSet;
    uint16 ownerRevShareInBasisPoints;
    address payable operatorRecipient;
    uint16 operatorRevShareInBasisPoints;
  }

  mapping(uint256 => RewardShares) private _tokenOrRecordIdToRecipients;

  modifier requireRecipients(Recipient[] calldata recipients) {
    require(recipients.length != 0, "PlayRewardShare: recipients are required");
    _;
  }

  modifier validTokenAmount(address paymentToken, uint256 tokenAmount) {
    require(tokenAmount != 0, "PlayRewardShare: tokenAmount is required");
    require(
      (paymentToken != address(0) && msg.value == 0) || (paymentToken == address(0) && msg.value == tokenAmount),
      "PlayRewardShare: Incorrect funds provided"
    );
    _;
  }

  function _deletePlayRewards(uint256 tokenOrRecordId) internal {
    delete _tokenOrRecordIdToRecipients[tokenOrRecordId];
    // Emit is not required, this can be inferred from other events already emitted.
  }

  function _setPlayRewardShares(
    uint256 tokenOrRecordId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  ) internal {
    require(!_tokenOrRecordIdToRecipients[tokenOrRecordId].isSet, "PlayRewardShare: Recipients already set");
    require(
      ownerRevShareInBasisPoints + operatorRevShareInBasisPoints < BASIS_POINTS,
      "PlayRewardShare: Total shares must be less than 100%"
    );

    _tokenOrRecordIdToRecipients[tokenOrRecordId] = RewardShares({
      isSet: true,
      ownerRevShareInBasisPoints: ownerRevShareInBasisPoints,
      operatorRecipient: operatorRecipient,
      operatorRevShareInBasisPoints: operatorRevShareInBasisPoints
    });
  }

  function _getPlayRewardShares(
    uint256 tokenOrRecordId,
    address player,
    address owner
  ) internal view returns (Recipient[] memory recipients) {
    uint256 recipientCount = 1;
    RewardShares memory shares;
    if (player != address(0)) {
      shares = _tokenOrRecordIdToRecipients[tokenOrRecordId];
    } else {
      // If not rented, all revenue goes to the owner which is assumed to be the current player.
      player = owner;
    }
    if (shares.ownerRevShareInBasisPoints != 0) {
      unchecked {
        ++recipientCount;
      }
    }
    if (shares.operatorRevShareInBasisPoints != 0) {
      unchecked {
        ++recipientCount;
      }
    }
    recipients = new Recipient[](recipientCount);

    if (shares.ownerRevShareInBasisPoints != 0) {
      if (shares.operatorRevShareInBasisPoints != 0) {
        recipients[1] = Recipient({
          to: payable(owner),
          role: RecipientRole.Owner,
          shareInBasisPoints: shares.ownerRevShareInBasisPoints
        });
        recipients[2] = Recipient({
          to: shares.operatorRecipient,
          role: RecipientRole.Operator,
          shareInBasisPoints: shares.operatorRevShareInBasisPoints
        });
      } else {
        recipients[1] = Recipient({
          to: payable(owner),
          role: RecipientRole.Owner,
          shareInBasisPoints: shares.ownerRevShareInBasisPoints
        });
      }
    } else if (shares.operatorRevShareInBasisPoints != 0) {
      recipients[1] = Recipient({
        to: shares.operatorRecipient,
        role: RecipientRole.Operator,
        shareInBasisPoints: shares.operatorRevShareInBasisPoints
      });
    }

    // Dynamically add the player, reduces storage requirements and allows for the user changing during a rental.
    recipients[0] = Recipient({
      to: payable(player),
      role: RecipientRole.Player,
      shareInBasisPoints: uint16(
        BASIS_POINTS - shares.ownerRevShareInBasisPoints - shares.operatorRevShareInBasisPoints
      )
    });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "solady/src/utils/Clone.sol";

/**
 * @title A mixin holding the original NFT contract address for wrapped NFT contracts.
 * @author batu-inal & HardlyDifficult
 */
abstract contract WrappedNFT is Clone {
  /**
   * @notice The address of the original NFT contract this wrapped NFT contract represents.
   */
  function originalNFTContract() public pure returns (address nftContract) {
    // See https://github.com/wighawag/clones-with-immutable-args for a description of how immutable proxy args work.
    nftContract = _getArgAddress(0);
  }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Helpers for working with arrays.
 * @author batu-inal & HardlyDifficult
 */
library ArrayLibrary {
  /**
   * @notice Removes the first instance of the given value from the array.
   * @dev Order is not preserved.
   */
  function remove(uint32[] storage values, uint32 value) internal {
    uint256 length = values.length;
    for (uint256 i = 0; i < length; ++i) {
      if (values[i] == value) {
        // Update length to represent the last index instead.
        --length;
        if (i != length) {
          // Swap in the last element so that we can pop from the end of the array.
          values[i] = values[length];
        }
        values.pop();
        return;
      }
    }

    // Value not found.
    // This should never be encountered given how this library is used in the Stash repo.
    assert(false);
  }
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
pragma solidity ^0.8.4;

/// @notice Class with helper read functions for clone with immutable args.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Clone.sol)
/// @author Adapted from clones with immutable args by zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
abstract contract Clone {
    /// @dev Reads an immutable arg with type bytes.
    function _getArgBytes(uint256 argOffset, uint256 length) internal pure returns (bytes memory arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            // Grab the free memory pointer.
            arg := mload(0x40)
            // Store the array length.
            mstore(arg, length)
            // Copy the array.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), length)
            // Allocate the memory, rounded up to the next 32 byte boudnary.
            mstore(0x40, and(add(add(arg, 0x3f), length), not(0x1f)))
        }
    }

    /// @dev Reads an immutable arg with type address.
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint256
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @dev Reads a uint256 array stored in the immutable args.
    function _getArgUint256Array(uint256 argOffset, uint256 length) internal pure returns (uint256[] memory arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            // Grab the free memory pointer.
            arg := mload(0x40)
            // Store the array length.
            mstore(arg, length)
            // Copy the array.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            // Allocate the memory.
            mstore(0x40, add(add(arg, 0x20), shl(5, length)))
        }
    }

    /// @dev Reads an immutable arg with type uint64.
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint8.
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata.
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        assembly {
            offset := sub(calldatasize(), shr(0xf0, calldataload(sub(calldatasize(), 2))))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/WrappedNFTs/StashWrapped1155.sol";

contract $StashWrapped1155 is StashWrapped1155 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _weth, address _contractFactory) StashWrapped1155(_weth, _contractFactory) {}

    function $_beforeTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._beforeTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_deleteUserRecord(uint32 recordId) external {
        return super._deleteUserRecord(recordId);
    }

    function $_wrap(address owner,uint256 id,uint256 amount) external {
        return super._wrap(owner,id,amount);
    }

    function $_deletePlayRewards(uint256 tokenOrRecordId) external {
        return super._deletePlayRewards(tokenOrRecordId);
    }

    function $_setPlayRewardShares(uint256 tokenOrRecordId,uint16 ownerRevShareInBasisPoints,address payable operatorRecipient,uint16 operatorRevShareInBasisPoints) external {
        return super._setPlayRewardShares(tokenOrRecordId,ownerRevShareInBasisPoints,operatorRecipient,operatorRevShareInBasisPoints);
    }

    function $_getPlayRewardShares(uint256 tokenOrRecordId,address player,address owner) external view returns (Recipient[] memory) {
        return super._getPlayRewardShares(tokenOrRecordId,player,owner);
    }

    function $_getArgBytes(uint256 argOffset,uint256 length) external pure returns (bytes memory) {
        return super._getArgBytes(argOffset,length);
    }

    function $_getArgAddress(uint256 argOffset) external pure returns (address) {
        return super._getArgAddress(argOffset);
    }

    function $_getArgUint256(uint256 argOffset) external pure returns (uint256) {
        return super._getArgUint256(argOffset);
    }

    function $_getArgUint256Array(uint256 argOffset,uint256 length) external pure returns (uint256[] memory) {
        return super._getArgUint256Array(argOffset,length);
    }

    function $_getArgUint64(uint256 argOffset) external pure returns (uint64) {
        return super._getArgUint64(argOffset);
    }

    function $_getArgUint8(uint256 argOffset) external pure returns (uint8) {
        return super._getArgUint8(argOffset);
    }

    function $_getImmutableArgsOffset() external pure returns (uint256) {
        return super._getImmutableArgsOffset();
    }

    function $_safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._safeTransferFrom(from,to,id,amount,data);
    }

    function $_safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function $_setURI(string calldata newuri) external {
        return super._setURI(newuri);
    }

    function $_mint(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mint(to,id,amount,data);
    }

    function $_mintBatch(address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._mintBatch(to,ids,amounts,data);
    }

    function $_burn(address from,uint256 id,uint256 amount) external {
        return super._burn(from,id,amount);
    }

    function $_burnBatch(address from,uint256[] calldata ids,uint256[] calldata amounts) external {
        return super._burnBatch(from,ids,amounts);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_afterTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._afterTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

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

import "../../../contracts/WrappedNFTs/interfaces/IStashWrapped1155Factory.sol";

abstract contract $IStashWrapped1155Factory is IStashWrapped1155Factory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/ContractFactory.sol";

contract $ContractFactory is ContractFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _contractFactory) ContractFactory(_contractFactory) {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/ERC5006.sol";

contract $ERC5006 is ERC5006 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(string memory uri_) ERC1155(uri_) {}

    function $_beforeTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._beforeTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_deleteUserRecord(uint32 recordId) external {
        return super._deleteUserRecord(recordId);
    }

    function $_safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._safeTransferFrom(from,to,id,amount,data);
    }

    function $_safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function $_setURI(string calldata newuri) external {
        return super._setURI(newuri);
    }

    function $_mint(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mint(to,id,amount,data);
    }

    function $_mintBatch(address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._mintBatch(to,ids,amounts,data);
    }

    function $_burn(address from,uint256 id,uint256 amount) external {
        return super._burn(from,id,amount);
    }

    function $_burnBatch(address from,uint256[] calldata ids,uint256[] calldata amounts) external {
        return super._burnBatch(from,ids,amounts);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_afterTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._afterTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/PlayRewardShare.sol";

contract $PlayRewardShare is PlayRewardShare {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_deletePlayRewards(uint256 tokenOrRecordId) external {
        return super._deletePlayRewards(tokenOrRecordId);
    }

    function $_setPlayRewardShares(uint256 tokenOrRecordId,uint16 ownerRevShareInBasisPoints,address payable operatorRecipient,uint16 operatorRevShareInBasisPoints) external {
        return super._setPlayRewardShares(tokenOrRecordId,ownerRevShareInBasisPoints,operatorRecipient,operatorRevShareInBasisPoints);
    }

    function $_getPlayRewardShares(uint256 tokenOrRecordId,address player,address owner) external view returns (Recipient[] memory) {
        return super._getPlayRewardShares(tokenOrRecordId,player,owner);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/PlayRewardShare1155.sol";

contract $PlayRewardShare1155 is PlayRewardShare1155 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _weth, string memory uri_) TokenTransfers(_weth) ERC1155(uri_) {}

    function $_deleteUserRecord(uint32 recordId) external {
        return super._deleteUserRecord(recordId);
    }

    function $_deletePlayRewards(uint256 tokenOrRecordId) external {
        return super._deletePlayRewards(tokenOrRecordId);
    }

    function $_setPlayRewardShares(uint256 tokenOrRecordId,uint16 ownerRevShareInBasisPoints,address payable operatorRecipient,uint16 operatorRevShareInBasisPoints) external {
        return super._setPlayRewardShares(tokenOrRecordId,ownerRevShareInBasisPoints,operatorRecipient,operatorRevShareInBasisPoints);
    }

    function $_getPlayRewardShares(uint256 tokenOrRecordId,address player,address owner) external view returns (Recipient[] memory) {
        return super._getPlayRewardShares(tokenOrRecordId,player,owner);
    }

    function $_beforeTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._beforeTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._safeTransferFrom(from,to,id,amount,data);
    }

    function $_safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function $_setURI(string calldata newuri) external {
        return super._setURI(newuri);
    }

    function $_mint(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mint(to,id,amount,data);
    }

    function $_mintBatch(address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._mintBatch(to,ids,amounts,data);
    }

    function $_burn(address from,uint256 id,uint256 amount) external {
        return super._burn(from,id,amount);
    }

    function $_burnBatch(address from,uint256[] calldata ids,uint256[] calldata amounts) external {
        return super._burnBatch(from,ids,amounts);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_afterTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._afterTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_transferFunds(address to,address paymentToken,uint256 amount) external {
        return super._transferFunds(to,paymentToken,amount);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/WrappedNFT.sol";

contract $WrappedNFT is WrappedNFT {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_getArgBytes(uint256 argOffset,uint256 length) external pure returns (bytes memory) {
        return super._getArgBytes(argOffset,length);
    }

    function $_getArgAddress(uint256 argOffset) external pure returns (address) {
        return super._getArgAddress(argOffset);
    }

    function $_getArgUint256(uint256 argOffset) external pure returns (uint256) {
        return super._getArgUint256(argOffset);
    }

    function $_getArgUint256Array(uint256 argOffset,uint256 length) external pure returns (uint256[] memory) {
        return super._getArgUint256Array(argOffset,length);
    }

    function $_getArgUint64(uint256 argOffset) external pure returns (uint64) {
        return super._getArgUint64(argOffset);
    }

    function $_getArgUint8(uint256 argOffset) external pure returns (uint8) {
        return super._getArgUint8(argOffset);
    }

    function $_getImmutableArgsOffset() external pure returns (uint256) {
        return super._getImmutableArgsOffset();
    }

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

import "../../contracts/libraries/ArrayLibrary.sol";

contract $ArrayLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    mapping(uint256 => uint32[]) internal $v_uint32_;

    constructor() {}

    function $remove(uint256 values,uint32 value) external payable {
        return ArrayLibrary.remove($v_uint32_[values],value);
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