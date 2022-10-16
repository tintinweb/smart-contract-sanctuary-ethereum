// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IERC4907.sol";
import "./interfaces/IStashWrapped721Factory.sol";
import "./interfaces/IPlayRewardShare721.sol";

import "../libraries/SupportsInterfaceUnchecked.sol";

import "../shared/TokenTransfers.sol";
import "./mixins/ContractFactory.sol";
import "./mixins/ERC4907.sol";
import "./mixins/PlayRewardShare.sol";
import "./mixins/PlayRewardShare721.sol";
import "./mixins/WrappedNFT.sol";

/**
 * @title A wrapped version of an ERC-721 NFT contract to enable rentals.
 * @author batu-inal & HardlyDifficult
 */
contract StashWrapped721 is
  IERC4907,
  IStashWrapped721Factory,
  IPlayRewardShare721,
  IERC165,
  ERC165,
  TokenTransfers,
  ContractFactory,
  IERC721,
  IERC721Metadata,
  ERC721,
  WrappedNFT,
  ERC4907,
  PlayRewardShare,
  PlayRewardShare721
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
    ERC721("", "") // No name/symbol for the template contract.
  // solhint-disable-next-line no-empty-blocks
  {
    // initialize is not required for proxy instances since the only instance data required is defined via immutable
    // proxy args. ERC721's name/symbol are overridden below.
  }

  /**
   * @inheritdoc IStashWrapped721Factory
   */
  function factoryWrap(address owner, uint256 tokenId) external onlyContractFactory {
    _wrap(owner, tokenId);
  }

  /**
   * @inheritdoc IStashWrapped721Factory
   */
  function factoryWrapAndSetApprovalForAll(
    address owner,
    uint256 tokenId,
    address operator
  ) external onlyContractFactory {
    _wrap(owner, tokenId);
    _setApprovalForAll(owner, operator);
  }

  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) public override(IERC4907, ERC4907, PlayRewardShare721) {
    super.setUser(tokenId, user, expires);
  }

  /**
   * @notice Wrap a specific NFT tokenId to enable rentals.
   * @param tokenId The tokenId of the NFT to wrap.
   * @dev This function is only callable by the owner of the original NFT.
   */
  function wrap(uint256 tokenId) external {
    _wrap(msg.sender, tokenId);
  }

  /**
   * @notice Wrap a specific NFT tokenId to enable rentals and grant approval for all on this wrapped contract for the
   * `msg.sender` (NFT owner) and the `operator` provided.
   * @param tokenId The tokenId of the NFT to wrap.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This function is only callable by the owner of the original NFT.
   */
  function wrapAndSetApprovalForAll(uint256 tokenId, address operator) external {
    _wrap(msg.sender, tokenId);
    _setApprovalForAll(msg.sender, operator);
  }

  /**
   * @notice Unwrap a specific NFT tokenId and transfer the original NFT to the `msg.sender`.
   * @param tokenId The tokenId of the NFT to unwrap.
   * @dev This function is only callable by the current owner of the wrapped NFT.
   * If the NFT is currently rented it may not be unwrapped.
   */
  function unwrap(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender, "StashWrapped721: Must be called by the owner");

    // Burn will revert if the NFT is currently rented
    _burn(tokenId);

    IERC721(originalNFTContract()).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /**
   * @notice Called anytime an NFT is minted, transferred, or burned.
   * @dev This instance is a no-op, here to prevent compile errors due to the inheritance used.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC4907, ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @notice Escrows the original NFT and mints a wrapped version.
   */
  function _wrap(address owner, uint256 tokenId) private {
    _mint(owner, tokenId);
    // Safe transfer is not required when sending to self.
    IERC721(originalNFTContract()).transferFrom(owner, address(this), tokenId);
  }

  /**
   * @notice Grants approval for all on this wrapped contract for the NFT owner and the `operator` provided.
   */
  function _setApprovalForAll(address owner, address operator) private {
    require(operator != address(0), "StashWrapped721: Operator cannot be zero address");
    _setApprovalForAll(owner, operator, true);
  }

  /**
   * @notice The name for this NFT contract.
   * @dev Returns the name from the original NFT contract, prefixed with "Wrapped ".
   */
  function name() public view override(IERC721Metadata, ERC721) returns (string memory _name) {
    _name = string.concat("Wrapped ", IERC721Metadata(originalNFTContract()).name());
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
    override(IERC165, ERC165, ERC721, ERC4907, PlayRewardShare721)
    returns (bool supported)
  {
    supported = super.supportsInterface(interfaceId);
  }

  /**
   * @notice The symbol for this NFT contract.
   * @dev Returns the symbol from the original NFT contract, prefixed with "W".
   */
  function symbol() public view override(IERC721Metadata, ERC721) returns (string memory _symbol) {
    _symbol = string.concat("W", IERC721Metadata(originalNFTContract()).symbol());
  }

  /**
   * @notice The URI for a specific NFT.
   * @param tokenId The tokenId of the NFT to get the URI for.
   * @dev Returns the URI from the original NFT contract.
   */
  function tokenURI(uint256 tokenId) public view override(IERC721Metadata, ERC721) returns (string memory uri) {
    uri = IERC721Metadata(originalNFTContract()).tokenURI(tokenId);
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

/**
 * @title Factory interface for ERC-721 wrapped NFTs.
 * @author batu-inal & HardlyDifficult
 */
interface IStashWrapped721Factory {
  /**
   * @notice Wrap a specific NFT tokenId to enable rentals.
   * @param owner The account that currently owns the original NFT.
   * @param tokenId The tokenId of the NFT to wrap.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrap(address owner, uint256 tokenId) external;

  /**
   * @notice Wrap a specific NFT tokenId to enable rentals and grant approval for all on this wrapped contract for the
   * NFT owner and the `operator` provided.
   * @param owner The account that currently owns the original NFT.
   * @param tokenId The tokenId of the NFT to wrap.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrapAndSetApprovalForAll(
    address owner,
    uint256 tokenId,
    address operator
  ) external;
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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../interfaces/IERC4907.sol";

import "../../libraries/Time.sol";

/**
 * @title Rental implementation for ERC-721.
 * @dev Modified from https://eips.ethereum.org/EIPS/eip-4907 reference impl
 * @author batu-inal & HardlyDifficult
 */
abstract contract ERC4907 is IERC4907, ERC721 {
  using Time for uint64;

  /**
   * @notice Details about a rental.
   * @param user The user who is renting the NFT.
   * @param expiry The time at which the rental expires.
   * @param operator The `msg.sender` which initiated the rental.
   */
  struct UserInfo {
    address user;
    uint64 expiry;
    address operator;
  }

  /**
   * @notice Mapping from token ID to rental information.
   */
  mapping(uint256 => UserInfo) private tokenIdToUserInfo;

  /**
   * @notice Emitted when rental terms are set by a user other than the NFT owner.
   * @param tokenId The NFT which is being rented.
   * @param operator The `msg.sender` which initiated the rental.
   */
  event UserOperatorSet(uint256 tokenId, address operator);

  /**
   * @inheritdoc IERC4907
   */
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) public virtual {
    address owner = ownerOf(tokenId);
    address operator;
    UserInfo storage info = tokenIdToUserInfo[tokenId];
    if (user != address(0)) {
      // Create a rental.

      require(!expires.hasExpired(), "ERC4907: Rental terms have expired");
      require(info.expiry.hasExpired(), "ERC4907: NFT is already rented");

      if (owner != msg.sender) {
        require(
          isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender,
          "ERC4907: Caller is not owner nor approved"
        );
        // Only store operator if it's not the NFT owner.
        operator = msg.sender;
      }

      // Store the operator, potentially clearing the data if the slot was previously used.
      info.operator = operator;
    } else {
      // Cancel a rental, by the operator or current renter.

      require(expires == 0, "ERC4907: expires must be 0");
      operator = info.operator;
      require(
        operator == msg.sender || (operator == address(0) && owner == msg.sender) || info.user == msg.sender,
        "ERC4907: Only the operator or renter can cancel rentals"
      );
    }

    info.user = user;
    info.expiry = expires;
    emit UpdateUser(tokenId, user, expires);

    // Operator is implied 0 when deleting the rental information.
    if (expires != 0) {
      // Although when owner == operator it is not saved in storage, we still emit the event for clarity.
      emit UserOperatorSet(tokenId, operator != address(0) ? operator : owner);
    }
  }

  /**
   * @notice Called anytime an NFT is minted, transferred, or burned.
   * @dev This instance will block transfers anytime there is an active rental.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    // Block transfers and unwrapping while there is an active rental.
    require(tokenIdToUserInfo[tokenId].expiry.hasExpired(), "ERC4907: NFT is already rented");
  }

  /**
   * @notice Checks if this contract implements the given ERC-165 interface.
   * @param interfaceId The interface to check for.
   * @return supported True if this contract implements the given interface.
   * @dev This instance checks the ERC-4907 interface.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool supported) {
    supported = interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC4907
   */
  function userExpires(uint256 tokenId) public view returns (uint256 expiry) {
    UserInfo storage info = tokenIdToUserInfo[tokenId];
    if (!info.expiry.hasExpired()) {
      expiry = info.expiry;
    }
    // Once expired, return 0 instead.
  }

  /**
   * @inheritdoc IERC4907
   */
  function userOf(uint256 tokenId) public view returns (address user) {
    UserInfo storage info = tokenIdToUserInfo[tokenId];
    if (!info.expiry.hasExpired()) {
      user = info.user;
    }
    // Once expired, return address(0) instead.
  }

  /**
   * @notice Get the operator for a rented NFT.
   * @param tokenId The NFT to get the operator of.
   * @return operator The `msg.sender` which initiated the rental.
   * @dev The zero address indicates that there is no longer any active renter of this NFT.
   */
  function userOperatorOf(uint256 tokenId) public view returns (address operator) {
    UserInfo storage info = tokenIdToUserInfo[tokenId];
    if (!info.expiry.hasExpired()) {
      operator = info.operator;
      if (operator == address(0)) {
        // If the operator is not set, it's assumed to be the current owner.
        operator = ownerOf(tokenId);
      }
    }
    // Once expired, return address(0) instead.
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

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IPlayRewardShare721.sol";
import "../interfaces/IERC4907.sol";

import "../../shared/Constants.sol";
import "../../shared/TokenTransfers.sol";

import "./ERC4907.sol";
import "./PlayRewardShare.sol";

/**
 * @title APIs for play rewards generated by this ERC-721 NFT.
 * @author batu-inal & HardlyDifficult
 */
abstract contract PlayRewardShare721 is
  IERC4907,
  IPlayRewardShare721,
  ERC165,
  TokenTransfers,
  ERC4907,
  PlayRewardShare
{
  /**
   * @inheritdoc IPlayRewardShare721
   */
  function payPlayRewards(
    uint256 tokenId,
    Recipient[] calldata recipients,
    address paymentToken,
    uint256 tokenAmount
  ) external payable validTokenAmount(paymentToken, tokenAmount) requireRecipients(recipients) {
    uint256 totalDistributed;
    uint256 length = recipients.length;
    for (uint256 i = 1; i < length; ) {
      uint256 toDistribute = (tokenAmount * recipients[i].shareInBasisPoints) / BASIS_POINTS;
      totalDistributed += toDistribute;
      _payReward(tokenId, recipients[i], paymentToken, toDistribute);

      unchecked {
        ++i;
      }
    }

    // Round in favor of the first recipient
    _payReward(tokenId, recipients[0], paymentToken, tokenAmount - totalDistributed);
  }

  /**
   * @inheritdoc IPlayRewardShare721
   */
  function setPlayRewardShares(
    uint256 tokenId,
    uint16 ownerRevShareInBasisPoints,
    address payable operatorRecipient,
    uint16 operatorRevShareInBasisPoints
  ) external {
    require(userOperatorOf(tokenId) == msg.sender, "PlayRewardShare721: Only the operator can set recipients");
    _setPlayRewardShares(tokenId, ownerRevShareInBasisPoints, operatorRecipient, operatorRevShareInBasisPoints);
    emit PlayRewardRecipientsSet(tokenId, ownerRevShareInBasisPoints, operatorRecipient, operatorRevShareInBasisPoints);
  }

  /**
   * @inheritdoc IERC4907
   * @dev Anytime the rental terms change, clear recorded play reward recipients. They can be reset by the operator
   * when applicable.
   */
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) public virtual override(IERC4907, ERC4907) {
    _deletePlayRewards(tokenId);
    super.setUser(tokenId, user, expires);
  }

  /**
   * @notice Distributes play reward payments to the given recipient, if the amount is greater than 0.
   */
  function _payReward(
    uint256 tokenId,
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
        role: recipient.role,
        paymentToken: paymentToken,
        tokenAmount: tokenAmount
      });
    }
  }

  /**
   * @inheritdoc IPlayRewardShare721
   */
  function getPlayRewardShares(uint256 tokenId) external view returns (Recipient[] memory recipients) {
    recipients = _getPlayRewardShares(tokenId, userOf(tokenId), ownerOf(tokenId));
  }

  /**
   * @notice Checks if this contract implements the given ERC-165 interface.
   * @param interfaceId The interface to check for.
   * @return supported True if this contract implements the given interface.
   * @dev This instance checks the IPlayRewardShare721 interface.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, ERC4907)
    returns (bool supported)
  {
    supported = interfaceId == type(IPlayRewardShare721).interfaceId || super.supportsInterface(interfaceId);
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
pragma solidity ^0.8.12;

interface IWeth {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);
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

import "../../contracts/WrappedNFTs/StashWrapped721.sol";

contract $StashWrapped721 is StashWrapped721 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _weth, address _contractFactory) StashWrapped721(_weth, _contractFactory) {}

    function $_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
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

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata data) external {
        return super._safeTransfer(from,to,tokenId,data);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata data) external {
        return super._safeMint(to,tokenId,data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_requireMinted(uint256 tokenId) external view {
        return super._requireMinted(tokenId);
    }

    function $_afterTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._afterTokenTransfer(from,to,tokenId);
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

import "../../../contracts/WrappedNFTs/interfaces/IERC4907.sol";

abstract contract $IERC4907 is IERC4907 {
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

import "../../../contracts/WrappedNFTs/interfaces/IStashWrapped721Factory.sol";

abstract contract $IStashWrapped721Factory is IStashWrapped721Factory {
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

import "../../../contracts/WrappedNFTs/mixins/ERC4907.sol";

contract $ERC4907 is ERC4907 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function $_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata data) external {
        return super._safeTransfer(from,to,tokenId,data);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata data) external {
        return super._safeMint(to,tokenId,data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_requireMinted(uint256 tokenId) external view {
        return super._requireMinted(tokenId);
    }

    function $_afterTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._afterTokenTransfer(from,to,tokenId);
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

import "../../../contracts/WrappedNFTs/mixins/PlayRewardShare721.sol";

contract $PlayRewardShare721 is PlayRewardShare721 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _weth, string memory name_, string memory symbol_) TokenTransfers(_weth) ERC721(name_, symbol_) {}

    function $_deletePlayRewards(uint256 tokenOrRecordId) external {
        return super._deletePlayRewards(tokenOrRecordId);
    }

    function $_setPlayRewardShares(uint256 tokenOrRecordId,uint16 ownerRevShareInBasisPoints,address payable operatorRecipient,uint16 operatorRevShareInBasisPoints) external {
        return super._setPlayRewardShares(tokenOrRecordId,ownerRevShareInBasisPoints,operatorRecipient,operatorRevShareInBasisPoints);
    }

    function $_getPlayRewardShares(uint256 tokenOrRecordId,address player,address owner) external view returns (Recipient[] memory) {
        return super._getPlayRewardShares(tokenOrRecordId,player,owner);
    }

    function $_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata data) external {
        return super._safeTransfer(from,to,tokenId,data);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata data) external {
        return super._safeMint(to,tokenId,data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_requireMinted(uint256 tokenId) external view {
        return super._requireMinted(tokenId);
    }

    function $_afterTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._afterTokenTransfer(from,to,tokenId);
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