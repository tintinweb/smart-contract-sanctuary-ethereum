// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/DepositInterface.sol";
import "./lib/ConfirmedOwner.sol";
import {DepositItem} from "./lib/DepositStructs.sol";

/**
 * @title DepositHelper
 * @notice DepositHelper is a utility contract for transferring
 *         ERC721 items in bulk to a fixed recipient.
 */
contract Deposit is DepositInterface, ConfirmedOwner {
  // Deposit enabled status
  bool public isEnabled;
  // recipient
  address public recipient;

  /**
   * @dev Reverts if the deposit is not enabled
   */
  modifier checkEnabled() {
    require(isEnabled, "Deposit suspended");
    _;
  }

  /**
   * @dev Set the supplied recipient.
   *
   *
   * @param _recipient The recipient address, used to receive
   *                          ERC721 tokens.
   * @param _owner The contract owner address.
   */
  constructor(address _recipient, address _owner) ConfirmedOwner(_owner) {
    recipient = _recipient;
    isEnabled = true;
  }

  /**
   * @dev Update recipient
   * @param _recipient  The new recipient.
   */
  function updateRecipient(address _recipient) external override onlyOwner {
    require(_recipient != recipient, "Not changed");
    require(_recipient != address(0), "Cannot set recipient to zero");
    address oldRecipient = recipient;
    recipient = _recipient;
    emit UpdateRecipient(oldRecipient, recipient);
  }

  /**
   * @notice Enable deposit
   */
  function enableDeposit() external override onlyOwner {
    if (!isEnabled) {
      isEnabled = true;

      emit EnableDeposit();
    }
  }

  /**
   * @notice Disable deposit
   */
  function disableDeposit() external override onlyOwner {
    if (isEnabled) {
      isEnabled = false;

      emit DisableDeposit();
    }
  }

  /**
   * @notice Transfer multiple ERC721 items to
   *         specified recipients.
   *
   * @param items      The items to transfer to an intended recipient.
   * @param requestId An optional request id from client.
   */
  function bulkDeposit(DepositItem[] calldata items, uint256 requestId) external override checkEnabled {
    require(items.length > 0, "Deposit items cannot be empty");
    // Perform transfers.
    // Iterate over each item in the items to perform ERC721 transfer.
    for (uint256 i = 0; i < items.length; ++i) {
      // Retrieve the item from the transfers.
      DepositItem calldata item = items[i];
      // Transfer ERC721 token.
      IERC721(item.token).safeTransferFrom(msg.sender, recipient, item.identifier);
    }

    // emit bulk deposit event
    emit BulkDeposit(requestId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev A DepositItem specifies token address, token identifier to be
 *      transferred via the Deposit.
 */
struct DepositItem {
  address token;
  uint256 identifier;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {DepositItem} from "../lib/DepositStructs.sol";

interface DepositInterface {
  /**
   * @dev Emit an event when the recipient is updated.
   *
   * @param from The old recipient
   * @param to The new recipient
   */
  event UpdateRecipient(address indexed from, address indexed to);

  /**
   * @dev Emit an event when the deposit is enabled.
   */
  event EnableDeposit();

  /**
   * @dev Emit an event when the deposit is disabled.
   */
  event DisableDeposit();

  /**
   * @dev Emit an event when the batch transfer is successful.
   *
   * @param requestId The request id from client
   */
  event BulkDeposit(uint256 indexed requestId);

  /**
   * @notice Update recipient
   *
   * @param recipient  The new recipient
   */
  function updateRecipient(address recipient) external;

  /**
   * @notice Enable deposit
   */
  function enableDeposit() external;

  /**
   * @notice Disable deposit
   */
  function disableDeposit() external;

  /**
   * @notice Deposit multiple items.
   *
   * @param items The items to transfer.
   * @param requestId  The request id from client.
   */
  function bulkDeposit(DepositItem[] calldata items, uint256 requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
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
pragma solidity ^0.8.7;

import "../interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == s_owner, "Only callable by owner");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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