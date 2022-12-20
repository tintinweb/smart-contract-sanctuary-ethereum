/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/// Constant values shared across mixins.

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10000;

/**
 * @dev Cap the number of royalty recipients.
 * A cap is required to ensure gas costs are not too high when a sale is settled.
 */
uint256 constant MAX_ROYALTY_RECIPIENTS = 5;

/**
 * @dev The minimum increase of 10% required when making an offer or placing a bid.
 */
uint256 constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1000;

/**
 * @dev The gas limit used when making external read-only calls.
 * This helps to ensure that external calls does not prevent the market from executing.
 */
uint256 constant READ_ONLY_GAS_LIMIT = 40000;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: contracts/interfaces/IAdminRole.sol


pragma solidity ^0.8.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// File: contracts/interfaces/IOperatorRole.sol


pragma solidity ^0.8.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function isOperator(address account) external view returns (bool);
}

// File: contracts/mixins/TreasuryNode.sol


pragma solidity ^0.8.0;


error TreasuryNode_Address_Is_Not_A_Contract();
error TreasuryNode_Caller_Not_Admin();
error TreasuryNode_Caller_Not_Operator();

/**
 * @title A mixin that stores a reference to the  treasury contract.
 * @notice The treasury collects fees and defines admin/operator roles.
 */
abstract contract TreasuryNode {
  using Address for address payable;

  /// @notice The address of the treasury contract.
  address payable private immutable treasury;

  /// @notice Requires the caller is a  admin.
  modifier onlyAdmin() {
    if (!IAdminRole(treasury).isAdmin(msg.sender)) {
      revert TreasuryNode_Caller_Not_Admin();
    }
    _;
  }

  /// @notice Requires the caller is a  operator.
  modifier onlyOperator() {
    if (!IOperatorRole(treasury).isOperator(msg.sender)) {
      revert TreasuryNode_Caller_Not_Operator();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Assigns the treasury contract address.
   */
  constructor(address payable _treasury) {
    if (!_treasury.isContract()) {
      revert TreasuryNode_Address_Is_Not_A_Contract();
    }
    treasury = _treasury;
  }

  /**
   * @notice Gets the  treasury contract.
   * @dev This call is used in the royalty registry contract.
   * @return treasuryAddress The address of the  treasury contract.
   */
  function getTreasury() public view returns (address payable treasuryAddress) {
    return treasury;
  }

}

// File: contracts/mixins/NFTMarketAuction.sol


pragma solidity ^0.8.0;


/**
 * @title An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction  {
  /**
   * @notice A global id for auctions of any type.
   */
  uint256 private nextAuctionId;

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This sets the initial auction id to 1, making the first auction cheaper
   * and id 0 represents no auction found.
   */
  function _initializeNFTMarketAuction() internal  {
    nextAuctionId = 1;
  }

  /**
   * @notice Returns id to assign to the next auction.
   */
  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    // AuctionId cannot overflow 256 bits.
    unchecked {
      return nextAuctionId++;
    }
  }

}

// File: contracts/interfaces/IOwnable.sol



pragma solidity ^0.8.0;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: contracts/interfaces/IMETHMarket.sol


pragma solidity ^0.8.0;

/**
 * @notice Interface for functions the market uses in METH.
 */
interface IMETHMarket {
  function depositFor(address account) external payable;

  function marketLockupFor(address account, uint256 amount) external payable returns (uint256 expiration);

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

  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable returns (uint256 expiration);
}

// File: contracts/mixins/NFTMarketCore.sol


pragma solidity ^0.8.0;


error NFTMarketCore_METH_Address_Is_Not_A_Contract();
error NFTMarketCore_Only_METH_Can_Transfer_ETH();
error NFTMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 */
abstract contract NFTMarketCore {
  using Address for address;

  /// @notice The METH ERC-20 token for managing escrow and lockup.
  IMETHMarket internal immutable METH;

  constructor(address _METH) {
    if (!_METH.isContract()) {
      revert NFTMarketCore_METH_Address_Is_Not_A_Contract();
    }
    METH = IMETHMarket(_METH);
  }

  /**
   * @notice Only used by METH. Any direct transfer from users will revert.
   */
  receive() external payable {
    if (msg.sender != address(METH)) {
      revert NFTMarketCore_Only_METH_Can_Transfer_ETH();
    }
  }

  /**
   * @notice If there is a buy price at this amount or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) internal virtual returns (bool);

  /**
   * @notice If there is a valid offer at the given price or higher, accept that and return true.
   */
  function _autoAcceptOffer(
    address nftContract,
    uint256 tokenId,
    uint256 minAmount
  ) internal virtual returns (bool);

  /**
   * @notice Notify implementors when an auction has received its first bid.
   * Once a bid is received the sale is guaranteed to the auction winner
   * and other sale mechanisms become unavailable.
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  function _beforeAuctionStarted(
    address, /*nftContract*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @notice Cancel the `msg.sender`'s offer if there is one, freeing up their METH balance.
   * @dev This should be used when it does not make sense to keep the original offer around,
   * e.g. if a collector accepts a Buy Price then keeping the offer around is not necessary.
   */
  function _cancelSendersOffer(address nftContract, uint256 tokenId) internal virtual;

  /**
   * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
   * @param authorizeSeller The address of the seller pending authorization.
   * Once it's been authorized by one of the escrow managers, it should be set to address(0)
   * indicated that it's no longer pending authorization.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual {
    if (authorizeSeller != address(0)) {
      revert NFTMarketCore_Seller_Not_Found();
    }
    IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
  }

  /**
   * @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual {
    IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
  }

  /**
   * @notice Transfers an NFT into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this NFT.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual {
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

  /**
   * @notice Gets the METH contract used to escrow offer funds.
   * @return METHAddress The METH contract address.
   */
  function getMETHAddress() external view returns (address METHAddress) {
    METHAddress = address(METH);
  }

  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount;
    unchecked {
      minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
    }
    if (minIncrement == 0) {
      // Since minIncrement reduces from the currentAmount, this cannot overflow.
      // The next amount must be at least 1 wei greater than the current.
      return currentAmount + 1;
    }

    return minIncrement + currentAmount;
  }

  /**
   * @notice Checks who the seller for an NFT is, checking escrow or return the current owner if not in escrow.
   * @dev If the NFT did not have an escrowed seller to return, fall back to return the current owner.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address payable seller) {
    seller = payable(IERC721(nftContract).ownerOf(tokenId));
  }

  /**
   * @notice Checks if an escrowed NFT is currently in active auction.
   * @return Returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view virtual returns (bool);

}

// File: contracts/mixins/SendValueWithFallbackWithdraw.sol


pragma solidity ^0.8.0;


error SendValueWithFallbackWithdraw_No_Funds_Available();

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the METH token contract for future withdrawal instead.
 * @dev This mixin was recently switched to escrow funds in METH.
 * Once we have confirmed all pending balances have been withdrawn, we can remove the escrow tracking here.
 */
abstract contract SendValueWithFallbackWithdraw is NFTMarketCore, ReentrancyGuard {
  using Address for address payable;

  /**
   * @notice Emitted when escrowed funds are withdrawn to METH.
   * @param user The account which has withdrawn ETH.
   * @param amount The amount of ETH which has been withdrawn.
   */
  event WithdrawalToMETH(address indexed user, uint256 amount);

  /**
   * @dev Attempt to send a user or contract ETH and
   * if it fails store the amount owned for later withdrawal in METH.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Store the funds that failed to send for the user in the METH token
      METH.depositFor{ value: amount }(user);
      emit WithdrawalToMETH(user, amount);
    }
  }

  function _trySendValue(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) internal returns (bool success) {
    if (amount == 0) {
      return false;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (success, ) = user.call{ value: amount, gas: gasLimit }("");
  }

}

// File: contracts/mixins/OZ/ERC165Checker.sol



pragma solidity ^0.8.0;

/**
 * @title Library to query ERC165 support.
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library OZERC165Checker {
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
    bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
    (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
  }
}

// File: contracts/mixins/NFTMarketFees.sol


pragma solidity ^0.8.0;



/**
 * @title A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is TreasuryNode, SendValueWithFallbackWithdraw {
  using Address for address;
  using OZERC165Checker for address;

  /// @notice The royalties sent to creator recipients on secondary sales.
  uint256 private constant CREATOR_ROYALTY_DENOMINATOR = BASIS_POINTS / 1000; // 10%
  /// @notice The fee collected by  for sales facilitated by this market contract.
  uint256 private constant PROTOCOL_FEE_DENOMINATOR = BASIS_POINTS / 500; // 5%

  // The NFT token address to creator address
  mapping (address => address) private royaltyReceiver;


  event SetRoyaltyReceiver(address caller, address indexed nftContract, address indexed royaltyAddress);

  constructor() {
   
  }

  /**
   * @notice getRoyaltyReceiverAddress.
   */
  function getRoyaltyReceiverAddress(address tokenAddress) external view returns(address) {
      return royaltyReceiver[tokenAddress];
  }

  /**
   * @notice setRoyaltyAddress}.
   */
  function setRoyaltyReceiverAddress(address tokenAddress, address royaltyAddress) public  {
      require(tokenAddress.isContract() && royaltyAddress != address(0), "Invalid input");     
      royaltyReceiver[tokenAddress] = royaltyAddress;
      emit SetRoyaltyReceiver(msg.sender, tokenAddress, royaltyAddress);
  }

  /**
   * @notice Distributes funds to , creator recipients, and NFT owner after a sale.
   */
  // solhint-disable-next-line code-complexity
  function _distributeFunds(
    address nftContract,
    address payable seller,
    uint256 price
  )
    internal
    returns (
      uint256 protocolFee,
      uint256 creatorFee,
      uint256 sellerRev
    )
  {

    address payable creator;
    address payable sellerRevTo;
    (protocolFee, creator, creatorFee, sellerRevTo, sellerRev) = _getFees(
      nftContract,
      seller,
      price
    );

    if (creatorFee != 0) {
      _sendValueWithFallbackWithdraw(creator, creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
    }
    _sendValueWithFallbackWithdraw(sellerRevTo, sellerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    // Calculate the  fee using the total protocol fee minus any referrals paid.
    unchecked {
      _sendValueWithFallbackWithdraw(
        getTreasury(),
        protocolFee,
        SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
      );
    }  
  }


  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The sale price to calculate the fees for.
   */
  function getFeesAndRecipients(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    external
    view
    returns (
      uint256 protocolFee,
      uint256 creatorRev,
      uint256 sellerRev,
      address payable owner
    )
  {
    address payable seller = _getSellerFor(nftContract, tokenId);
    // ProtocolFee == the full protocolFee since no referrers are defined here.
    (protocolFee, ,creatorRev, owner, sellerRev) = _getFees(
      nftContract,
      seller,
      price
    );
  }

  /**
   * @notice For internal use only.
   * @dev This function is external to allow using try/catch but is not intended for external use.
   * This checks for royalties defined in the royalty registry.
   */
  
  function getRoyaltieReceiver(
    address nftContract
  ) public view returns (address payable recipient) {

    if(royaltyReceiver[nftContract] != address(0x00)){
      // return the royalty receiver if there was royalty defined
      recipient = payable(royaltyReceiver[nftContract]);
      return recipient;
    } else {
      // owner from contract 
        try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address owner) {
        if (owner != address(0)) {
          // Only pay the owner if there wasn't another royalty defined
          recipient = payable(owner);
          return (recipient);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
      // If no valid royalty payment receiver address, return 0 recipient
    }
  }

  /**
   * @notice Calculates how funds should be distributed for the given sale details.
   * @dev When the NFT is being sold by the `tokenCreator`, all the seller revenue will
   * be split with the royalty recipients defined for that NFT.
   */
  function _getFees(
    address nftContract,
    address payable seller,
    uint256 price
  )
    private
    view
    returns (
      uint256 protocolFee,
      address payable creator,
      uint256 creatorRev,
      address payable sellerRevTo,
      uint256 sellerRev
    )
  {  
    creator = getRoyaltieReceiver(nftContract);

      // Calculate the protocol fee
    unchecked {
      // SafeMath is not required when dividing by a non-zero constant.
      protocolFee = price / PROTOCOL_FEE_DENOMINATOR;
    }

      if (seller == creator ) {
        // When sold by the creator, all revenue is split if applicable.
        unchecked {
          // protocolFee is always < price.
          creatorRev = price - protocolFee;
        }
      } else if (seller != address(0x00)) {
        // Rounding favors the owner first, then creator, and  last.
        unchecked {
          // SafeMath is not required when dividing by a non-zero constant.
          creatorRev = price / CREATOR_ROYALTY_DENOMINATOR;
        }
        sellerRevTo = seller;
        sellerRev = price - protocolFee - creatorRev;
      } else {
      // No royalty recipients found.
      sellerRevTo = seller;
      unchecked {
        // protocolFee is always < price.
        sellerRev = price - protocolFee;
      }
    }
  
  }

 
}

// File: contracts/mixins/NFTMarketBuyPrice.sol


pragma solidity ^0.8.0;

/// @param buyPrice The current buy price set for this NFT.
error NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(uint256 buyPrice);
error NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
error NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(address owner);
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Set_Price(address owner);
error NFTMarketBuyPrice_Price_Already_Set();
error NFTMarketBuyPrice_Price_Too_High();
/// @param seller The current owner of this NFT.
error NFTMarketBuyPrice_Seller_Mismatch(address seller);

/**
 * @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
 * @notice NFTs with a buy price set are escrowed in the market contract.
 */
abstract contract NFTMarketBuyPrice is NFTMarketFees {
  using Address for address payable;

  /// @notice Stores the buy price details for a specific NFT.
  /// @dev The struct is packed into a single slot to optimize gas.
  struct BuyPrice {
    /// @notice The current owner of this NFT which set a buy price.
    /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
    address payable seller;
    /// @notice The current buy price set for this NFT.
    uint96 price;
  }

  /// @notice Stores the current buy price for each NFT.
  mapping(address => mapping(uint256 => BuyPrice)) private nftContractToTokenIdToBuyPrice;

  /**
   * @notice Emitted when an NFT is bought by accepting the buy price,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The total buy price that was accepted is `protocolFee` + `creatorFee` + `sellerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that purchased the NFT using `buy`.
   * @param seller The address of the seller which originally set the buy price.
   * @param protocolFee The amount of ETH that was sent to  for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event BuyPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 protocolFee,
    uint256 creatorFee,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when the buy price is removed by the owner of an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceCanceled(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is invalidated due to other market activity.
   * @dev This occurs when the buy price is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceInvalidated(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is set by the owner of an NFT.
   * @dev The NFT is transferred into the market contract for escrow unless it was already escrowed,
   * e.g. for auction listing.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param seller The address of the NFT owner which set the buy price.
   * @param price The price of the NFT.
   */
  event BuyPriceSet(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);



  /**
   * @notice Buy the NFT at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available METH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param maxPrice The maximum price to pay for the NFT.
   */
  function buy(
    address nftContract,
    uint256 tokenId,
    uint256 maxPrice
  ) public payable {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.price > maxPrice) {
      revert NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.price);
    } else if (buyPrice.seller == address(0)) {
      revert NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
    }

    _buy(nftContract, tokenId);
  }

  /**
   * @notice Removes the buy price set for an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  function cancelBuyPrice(address nftContract, uint256 tokenId) external nonReentrant {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Transfer the NFT back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(nftContract, tokenId, msg.sender);

    emit BuyPriceCanceled(nftContract, tokenId);
  }

  /**
   * @notice Sets the buy price for an NFT and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The price at which someone could buy this NFT.
   */
  function setBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) external nonReentrant {
    // If there is a valid offer at this price or higher, accept that instead.
    if (_autoAcceptOffer(nftContract, tokenId, price)) {
      return;
    }

    if (price > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert NFTMarketBuyPrice_Price_Too_High();
    }

    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    address seller = buyPrice.seller;

    if (buyPrice.price == price && seller != address(0)) {
      revert NFTMarketBuyPrice_Price_Already_Set();
    }

    // Store the new price for this NFT.
    buyPrice.price = uint96(price);

    if (seller == address(0)) {
      // Transfer the NFT into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      _transferToEscrow(nftContract, tokenId);

      // The price was not previously set for this NFT, store the seller.
      buyPrice.seller = payable(msg.sender);
    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert NFTMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    emit BuyPriceSet(nftContract, tokenId, msg.sender, price);
  }

  /**
   * @notice If there is a buy price at this price or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 maxPrice
  ) internal override returns (bool) {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.seller == address(0) || buyPrice.price > maxPrice) {
      // No buy price was found, or the price is too high.
      return false;
    }

    _buy(nftContract, tokenId);
    return true;
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price on a auction start, if one is found.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.seller != address(0)) {
      // A buy price was set for this NFT, invalidate it.
      _invalidateBuyPrice(nftContract, tokenId);
    }
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @notice Process the purchase of an NFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(
    address nftContract,
    uint256 tokenId
  ) private nonReentrant {
    BuyPrice memory buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Remove the buy now price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Cancel the buyer's offer if there is one in order to free up their METH balance
    // even if they don't need the METH for this specific purchase.
    _cancelSendersOffer(nftContract, tokenId);

    if (buyPrice.price > msg.value) {
      // Withdraw additional ETH required from their available METH balance.

      unchecked {
        // The if above ensures delta will not underflow.
        uint256 delta = buyPrice.price - msg.value;
        // Withdraw ETH from the buyer's account in the METH token contract,
        // making the ETH available for `_distributeFunds` below.
        METH.marketWithdrawFrom(msg.sender, delta);
      }
    } else if (buyPrice.price < msg.value) {
      // Return any surplus funds to the buyer.

      unchecked {
        // The if above ensures this will not underflow
        payable(msg.sender).sendValue(msg.value - buyPrice.price);
      }
    }

    // Transfer the NFT to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    _transferFromEscrow(nftContract, tokenId, msg.sender, address(0));

    // Distribute revenue for this sale.
    (uint256 protocolFee, uint256 creatorFee, uint256 sellerRev) = _distributeFunds(
      nftContract,
      buyPrice.seller,
      buyPrice.price
    );

    emit BuyPriceAccepted(nftContract, tokenId, buyPrice.seller, msg.sender, protocolFee, creatorFee, sellerRev);
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address nftContract, uint256 tokenId) private {
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    emit BuyPriceInvalidated(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price if one is found before transferring the NFT.
   * This will revert if there is a buy price set but the `authorizeSeller` is not the owner.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller != address(0)) {
      // A buy price was set for this NFT.
      // `authorizeSeller != address(0) &&` could be added when other mixins use this flow.
      // ATM that additional check would never return false.
      if (seller != authorizeSeller) {
        // When there is a buy price set, the `buyPrice.seller` is the owner of the NFT.
        revert NFTMarketBuyPrice_Seller_Mismatch(seller);
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);

      // Invalidate the buy price as the NFT will no longer be in escrow.
      _invalidateBuyPrice(nftContract, tokenId);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this NFT so it should remain in escrow.
      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if the NFT is already in escrow for buy now.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // The NFT is not in escrow for buy now.
      super._transferToEscrow(nftContract, tokenId);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the NFT.
      revert NFTMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

  /**
   * @notice Returns the buy price details for an NFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return seller The address of the owner that listed a buy price for this NFT.
   * Returns `address(0)` if there is no buy price set for this NFT.
   * @return price The price of the NFT.
   * Returns `0` if there is no buy price set for this NFT.
   */
  function getBuyPrice(address nftContract, uint256 tokenId) external view returns (address seller, uint256 price) {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      return (seller, type(uint256).max);
    }
    price = nftContractToTokenIdToBuyPrice[nftContract][tokenId].price;
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Returns the seller if there is a buy price set for this NFT, otherwise
   * bubbles the call up for other considerations.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      seller = super._getSellerFor(nftContract, tokenId);
    }
  }


}

// File: contracts/mixins/NFTMarketOffer.sol


pragma solidity ^0.8.0;

error NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
/// @param currentOfferAmount The current highest offer available for this NFT.
error NFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
/// @param expiry The time at which the offer had expired.
error NFTMarketOffer_Offer_Expired(uint256 expiry);
/// @param currentOfferFrom The address of the collector which has made the current highest offer.
error NFTMarketOffer_Offer_From_Does_Not_Match(address currentOfferFrom);
/// @param minOfferAmount The minimum amount that must be offered in order for it to be accepted.
error NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);
error NFTMarketOffer_Reason_Required();
error NFTMarketOffer_Provided_Contract_And_TokenId_Count_Must_Match();

/**
 * @title Allows collectors to make an offer for an NFT, valid for 24-25 hours.
 * @notice Funds are escrowed in the METH ERC-20 token contract.
 */
abstract contract NFTMarketOffer is NFTMarketFees {
  using Address for address;

  /// @notice Stores offer details for a specific NFT.
  struct Offer {
    // Slot 1: When increasing an offer, only this slot is updated.
    /// @notice The expiration timestamp of when this offer expires.
    uint32 expiration;
    /// @notice The amount, in wei, of the highest offer.
    uint96 amount;
    // Slot 2: When the buyer changes, both slots need updating
    /// @notice The address of the collector who made this offer.
    address buyer;
  
  }

  /// @notice Stores the highest offer for each NFT.
  mapping(address => mapping(uint256 => Offer)) private nftContractToIdToOffer;

  /**
   * @notice Emitted when an offer is accepted,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The accepted total offer amount is `protocolFee` + `creatorFee` + `sellerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that made the offer which was accepted.
   * @param seller The address of the seller which accepted the offer.
   * @param protocolFee The amount of ETH that was sent to  for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event OfferAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 protocolFee,
    uint256 creatorFee,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when an offer is canceled by a  admin.
   * @dev This should only be used for extreme cases such as DMCA takedown requests.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param reason The reason for the cancellation (a required field).
   */
  event OfferCanceledByAdmin(address indexed nftContract, uint256 indexed tokenId, string reason);
  /**
   * @notice Emitted when an offer is invalidated due to other market activity.
   * When this occurs, the collector which made the offer has their METH balance unlocked
   * and the funds are available to place other offers or to be withdrawn.
   * @dev This occurs when the offer is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event OfferInvalidated(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when an offer is made.
   * @dev The `amount` of the offer is locked in the METH ERC-20 contract, guaranteeing that the funds
   * remain available until the `expiration` date.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that made the offer to buy this NFT.
   * @param amount The amount, in wei, of the offer.
   * @param expiration The expiration timestamp for the offer.
   */
  event OfferMade(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 amount,
    uint256 expiration
  );

  /**
   * @notice Accept the highest offer for an NFT.
   * @dev The offer must not be expired and the NFT owned + approved by the seller or
   * available in the market contract's escrow.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param offerFrom The address of the collector that you wish to sell to.
   * If the current highest offer is not from this user, the transaction will revert.
   * This could happen if a last minute offer was made by another collector,
   * and would require the seller to try accepting again.
   * @param minAmount The minimum value of the highest offer for it to be accepted.
   * If the value is less than this amount, the transaction will revert.
   * This could happen if the original offer expires and is replaced with a smaller offer.
   */
  function acceptOffer(
    address nftContract,
    uint256 tokenId,
    address offerFrom,
    uint256 minAmount
  ) external nonReentrant {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    // Validate offer expiry and amount
    if (offer.expiration < block.timestamp) {
      revert NFTMarketOffer_Offer_Expired(offer.expiration);
    } else if (offer.amount < minAmount) {
      revert NFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    }
    // Validate the buyer
    if (offer.buyer != offerFrom) {
      revert NFTMarketOffer_Offer_From_Does_Not_Match(offer.buyer);
    }

    _acceptOffer(nftContract, tokenId);
  }

  /**
   * @notice Allows  to cancel offers.
   * This will unlock the funds in the METH ERC-20 contract for the highest offer
   * and prevent the offer from being accepted.
   * @dev This should only be used for extreme cases such as DMCA takedown requests.
   * @param nftContracts The addresses of the NFT contracts to cancel. This must be the same length as `tokenIds`.
   * @param tokenIds The ids of the NFTs to cancel. This must be the same length as `nftContracts`.
   * @param reason The reason for the cancellation (a required field).
   */
  function adminCancelOffers(
    address[] calldata nftContracts,
    uint256[] calldata tokenIds,
    string calldata reason
  ) external onlyAdmin nonReentrant {
    if (bytes(reason).length == 0) {
      revert NFTMarketOffer_Reason_Required();
    }
    if (nftContracts.length != tokenIds.length) {
      revert NFTMarketOffer_Provided_Contract_And_TokenId_Count_Must_Match();
    }

    // The array length cannot overflow 256 bits
    unchecked {
      for (uint256 i = 0; i < nftContracts.length; ++i) {
        Offer memory offer = nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];
        delete nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];

        if (offer.expiration >= block.timestamp) {
          // Unlock from escrow and emit an event only if the offer is still active
          METH.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);
          emit OfferCanceledByAdmin(nftContracts[i], tokenIds[i], reason);
        }
        // Else continue on so the rest of the batch transaction can process successfully
      }
    }
  }

  /**
   * @notice Make an offer for any NFT which is valid for 24-25 hours.
   * The funds will be locked in the METH token contract and become available once the offer is outbid or has expired.
   * @dev An offer may be made for an NFT before it is minted, although we generally not recommend you do that.
   * If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available METH balance.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param amount The amount to offer for this NFT.
   * @return expiration The timestamp for when this offer will expire.
   * This is provided as a return value in case another contract would like to leverage this information,
   * user's should refer to the expiration in the `OfferMade` event log.
   * If the buy price is accepted instead, `0` is returned as the expiration since that's n/a.
   */
  function makeOffer(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) public payable returns (uint256 expiration) {
    // If there is a buy price set at this price or lower, accept that instead.
    if (_autoAcceptBuyPrice(nftContract, tokenId, amount)) {
      // If the buy price is accepted, `0` is returned as the expiration since that's n/a.
      return 0;
    }

    if (_isInActiveAuction(nftContract, tokenId)) {
      revert NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
    }

    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];

    if (offer.expiration < block.timestamp) {
      // This is a new offer for the NFT (no other offer found or the previous offer expired)

      // Lock the offer amount in METH until the offer expires in 24-25 hours.
      expiration = METH.marketLockupFor{ value: msg.value }(msg.sender, amount);
    } else {
      // A previous offer exists and has not expired

      uint256 minIncrement = _getMinIncrement(offer.amount);
      if (amount < minIncrement) {
        // A non-trivial increase in price is required to avoid sniping
        revert NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(minIncrement);
      }

      // Unlock the previous offer so that the METH tokens are available for other offers or to transfer / withdraw
      // and lock the new offer amount in METH until the offer expires in 24-25 hours.
      expiration = METH.marketChangeLockup{ value: msg.value }(
        offer.buyer,
        offer.expiration,
        offer.amount,
        msg.sender,
        amount
      );
    }

    // Record offer details
    offer.buyer = msg.sender;
    // The METH contract guarantees that the expiration fits into 32 bits.
    offer.expiration = uint32(expiration);
    // `amount` is capped by the ETH provided, which cannot realistically overflow 96 bits.
    offer.amount = uint96(amount);
  

    emit OfferMade(nftContract, tokenId, msg.sender, amount, expiration);
  }



  /**
   * @notice Accept the highest offer for an NFT from the `msg.sender` account.
   * The NFT will be transferred to the buyer and revenue from the sale will be distributed.
   * @dev The caller must validate the expiry and amount before calling this helper.
   * This may invalidate other market tools, such as clearing the buy price if set.
   */
  function _acceptOffer(address nftContract, uint256 tokenId) private {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];

    // Remove offer
    delete nftContractToIdToOffer[nftContract][tokenId];
    // Withdraw ETH from the buyer's account in the METH token contract.
    METH.marketWithdrawLocked(offer.buyer, offer.expiration, offer.amount);

    // Transfer the NFT to the buyer.
    try
      IERC721(nftContract).transferFrom(msg.sender, offer.buyer, tokenId) // solhint-disable-next-line no-empty-blocks
    {
      // NFT was in the seller's wallet so the transfer is complete.
    } catch {
      // If the transfer fails then attempt to transfer from escrow instead.
      // This should revert if `msg.sender` is not the owner of this NFT.
      _transferFromEscrow(nftContract, tokenId, offer.buyer, msg.sender);
    }

    // Distribute revenue for this sale leveraging the ETH received from the METH contract in the line above.
    (uint256 protocolFee, uint256 creatorFee, uint256 sellerRev) = _distributeFunds(
      nftContract,
      payable(msg.sender),
      offer.amount
    );

    emit OfferAccepted(nftContract, tokenId, offer.buyer, msg.sender, protocolFee, creatorFee, sellerRev);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the highest offer when an auction is kicked off, if one is found.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateOffer(nftContract, tokenId);
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _autoAcceptOffer(
    address nftContract,
    uint256 tokenId,
    uint256 minAmount
  ) internal override returns (bool) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration < block.timestamp || offer.amount < minAmount) {
      // No offer found, the most recent offer is now expired, or the highest offer is below the minimum amount.
      return false;
    }

    _acceptOffer(nftContract, tokenId);
    return true;
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _cancelSendersOffer(address nftContract, uint256 tokenId) internal override {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.buyer == msg.sender) {
      _invalidateOffer(nftContract, tokenId);
    }
  }

  /**
   * @notice Invalidates the offer and frees ETH from escrow, if the offer has not already expired.
   * @dev Offers are not invalidated when the NFT is purchased by accepting the buy price unless it
   * was purchased by the same user.
   * The user which just purchased the NFT may have buyer's remorse and promptly decide they want a fast exit,
   * accepting a small loss to limit their exposure.
   */
  function _invalidateOffer(address nftContract, uint256 tokenId) private {
    if (nftContractToIdToOffer[nftContract][tokenId].expiration >= block.timestamp) {
      // An offer was found and it has not already expired
      Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];

      // Remove offer
      delete nftContractToIdToOffer[nftContract][tokenId];

      // Unlock the offer so that the METH tokens are available for other offers or to transfer / withdraw
      METH.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);

      emit OfferInvalidated(nftContract, tokenId);
    }
  }

  /**
   * @notice Returns the minimum amount a collector must offer for this NFT in order for the offer to be valid.
   * @dev Offers for this NFT which are less than this value will revert.
   * Once the previous offer has expired smaller offers can be made.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return minimum The minimum amount that must be offered for this NFT.
   */
  function getMinOfferAmount(address nftContract, uint256 tokenId) external view returns (uint256 minimum) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration >= block.timestamp) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  /**
   * @notice Returns details about the current highest offer for an NFT.
   * @dev Default values are returned if there is no offer or the offer has expired.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return buyer The address of the buyer that made the current highest offer.
   * Returns `address(0)` if there is no offer or the most recent offer has expired.
   * @return expiration The timestamp that the current highest offer expires.
   * Returns `0` if there is no offer or the most recent offer has expired.
   * @return amount The amount being offered for this NFT.
   * Returns `0` if there is no offer or the most recent offer has expired.
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
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration < block.timestamp) {
      // Offer not found or has expired
      return (address(0), 0, 0);
    }

    // An offer was found and it has not yet expired.
    return (offer.buyer, offer.expiration, offer.amount);
  }


}

// File: contracts/mixins/NFTMarketReserveAuction.sol


pragma solidity ^0.8.0;


/// @param auctionId The already listed auctionId for this NFT.
error NFTMarketReserveAuction_Already_Listed(uint256 auctionId);
/// @param minAmount The minimum amount that must be bid in order for it to be accepted.
error NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
error NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
/// @param reservePrice The current reserve price.
error NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
/// @param endTime The timestamp at which the auction had ended.
error NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
/// @param endTime The timestamp at which the auction will end.
error NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
error NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
/// @param maxDuration The maximum configuration for a duration of the auction, in seconds.
error NFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
/// @param extensionDuration The extension duration, in seconds.
error NFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
error NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
/// @param seller The current owner of the NFT.
error NFTMarketReserveAuction_Not_Matching_Seller(address seller);
/// @param owner The current owner of the NFT.
error NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(address owner);
error NFTMarketReserveAuction_Price_Already_Set();
error NFTMarketReserveAuction_Too_Much_Value_Provided();

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 * @dev There is room to optimize the storage for auctions, significantly reducing gas costs.
 */
abstract contract NFTMarketReserveAuction is NFTMarketFees, NFTMarketAuction {
  /// @notice The auction configuration for a specific NFT.
  struct ReserveAuction {
    /// @notice The address of the NFT contract.
    address nftContract;
    /// @notice The id of the NFT.
    uint256 tokenId;
    /// @notice The owner of the NFT which listed it in auction.
    address payable seller;
    /// @notice The duration for this auction.
    uint256 duration;
    /// @notice The extension window for this auction.
    uint256 extensionDuration;
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

  /// @notice Stores the auction configuration for a specific NFT.
  /// @dev This allows us to modify the storage struct without changing external APIs.
  struct ReserveAuctionStorage {
    /// @notice The address of the NFT contract.
    address nftContract;
    /// @notice The id of the NFT.
    uint256 tokenId;
    /// @notice The owner of the NFT which listed it in auction.
    address payable seller;   
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

  /// @notice The auction configuration for a specific auction id.
  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  /// @notice The auction id for a specific NFT.
  /// @dev This is deleted when an auction is finalized or canceled.
  mapping(uint256 => ReserveAuctionStorage) private auctionIdToAuction;

  /// @notice How long an auction lasts for once the first bid has been received.
  uint256 private immutable DURATION;

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 private constant EXTENSION_DURATION = 15 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 private constant MAX_MAX_DURATION = 1000 days;

  /**
   * @notice Emitted when a bid is placed.
   * @param auctionId The id of the auction this bid was for.
   * @param bidder The address of the bidder.
   * @param amount The amount of the bid.
   * @param endTime The new end time of the auction (which may have been set or extended by this bid).
   */
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  /**
   * @notice Emitted when an auction is cancelled.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId The id of the auction that was cancelled.
   */
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  /**
   * @notice Emitted when an auction is canceled by a  admin.
   * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
   * @param auctionId The id of the auction that was cancelled.
   * @param reason The reason for the cancellation.
   */
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  /**
   * @notice Emitted when an NFT is listed for auction.
   * @param seller The address of the seller.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param duration The duration of the auction (always 24-hours).
   * @param extensionDuration The duration of the auction extension window (always 15-minutes).
   * @param reservePrice The reserve price to kick off the auction.
   * @param auctionId The id of the auction that was created.
   */
  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  /**
   * @notice Emitted when an auction that has already ended is finalized,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The amount of the highest bid / final sale price for this auction
   * is `protocolFee` + `creatorFee` + `sellerRev`.
   * @param auctionId The id of the auction that was finalized.
   * @param seller The address of the seller.
   * @param bidder The address of the highest bidder that won the NFT.
   * @param protocolFee The amount of ETH that was sent to  for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 protocolFee,
    uint256 creatorFee,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when an auction is invalidated due to other market activity.
   * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
   * @param auctionId The id of the auction that was invalidated.
   */
  event ReserveAuctionInvalidated(uint256 indexed auctionId);
  /**
   * @notice Emitted when the auction's reserve price is changed.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId The id of the auction that was updated.
   * @param reservePrice The new reserve price for the auction.
   */
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

  /// @notice Confirms that the reserve price is not zero.
  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    if (reservePrice == 0) {
      revert NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
    }
    _;
  }

  /**
   * @notice Configures the duration for auctions.
   * @param duration The duration for auctions, in seconds.
   */
  constructor(uint256 duration) {
    if (duration > MAX_MAX_DURATION) {
      // This ensures that math in this file will not overflow due to a huge duration.
      revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
    }
    if (duration < EXTENSION_DURATION) {
      // The auction duration configuration must be greater than the extension window of 15 minutes
      revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
    }
    DURATION = duration;
  }

  /**
   * @notice Allows  to cancel an auction, refunding the bidder and returning the NFT to
   * the seller (if not active buy price set).
   * This should only be used for extreme cases such as DMCA takedown requests.
   * @param auctionId The id of the auction to cancel.
   * @param reason The reason for the cancellation (a required field).
   */
  function adminCancelReserveAuction(uint256 auctionId, string calldata reason)
    external
    onlyAdmin
    nonReentrant
  {
    if (bytes(reason).length == 0) {
      revert NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
    }
    ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];
    if (auction.amount == 0) {
      revert NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    // Return the NFT to the owner.
    _transferFromEscrowIfAvailable(auction.nftContract, auction.tokenId, auction.seller);

    if (auction.bidder != address(0)) {
      // Refund the highest bidder if any bids were placed in this auction.
      _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit ReserveAuctionCanceledByAdmin(auctionId, reason);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * @dev The NFT is transferred back to the owner unless there is still a buy price set.
   * @param auctionId The id of the auction to cancel.
   */
  function cancelReserveAuction(uint256 auctionId) external nonReentrant {
    ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    // Transfer the NFT unless it still has a buy price set.
    _transferFromEscrowIfAvailable(auction.nftContract, auction.tokenId, auction.seller);

    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param reservePrice The initial reserve price for the auction.
   */
  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
    uint256 auctionId = _getNextAndIncrementAuctionId();

    // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
    _transferToEscrow(nftContract, tokenId);

    // This check must be after _transferToEscrow in case auto-settle was required
    if (nftContractToTokenIdToAuctionId[nftContract][tokenId] != 0) {
      revert NFTMarketReserveAuction_Already_Listed(nftContractToTokenIdToAuctionId[nftContract][tokenId]);
    }

    // Store the auction details
    nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    auction.nftContract = nftContract;
    auction.tokenId = tokenId;
    auction.seller = payable(msg.sender);
    auction.amount = reservePrice;

    emit ReserveAuctionCreated(msg.sender, nftContract, tokenId, DURATION, EXTENSION_DURATION, reservePrice, auctionId);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   * @param auctionId The id of the auction to settle.
   */
  function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
    if (auctionIdToAuction[auctionId].endTime == 0) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
    }
    _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
  }


  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @dev `amount` - `msg.value` is withdrawn from the bidder's METH balance.
   * @param auctionId The id of the auction to bid on.
   * @param amount The amount to bid, if this is more than `msg.value` funds will be withdrawn from your METH balance.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBid(
    uint256 auctionId,
    uint256 amount
  ) public payable nonReentrant {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];

    if (auction.amount == 0) {
      // No auction found
      revert NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
    } else if (amount < msg.value) {
      // The amount is specified by the bidder, so if too much ETH is sent then something went wrong.
      revert NFTMarketReserveAuction_Too_Much_Value_Provided();
    }

    uint256 endTime = auction.endTime;

    if (endTime == 0) {
      // This is the first bid, kicking off the auction.

      if (amount < auction.amount) {
        // The bid must be >= the reserve price.
        revert NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(auction.amount);
      }

      // Notify other market tools that an auction for this NFT has been kicked off.
      // The only state change before this call is potentially withdrawing funds from METH.
      _beforeAuctionStarted(auction.nftContract, auction.tokenId);

      // Store the bid details.
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      // On the first bid, set the endTime to now + duration.
      unchecked {
        // Duration is always set to 24hrs so the below can't overflow.
        endTime = block.timestamp + DURATION;
      }
      auction.endTime = endTime;
    } else {
      if (endTime < block.timestamp) {
        // The auction has already ended.
        revert NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(endTime);
      } else if (auction.bidder == msg.sender) {
        // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
        revert NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      } else {
        uint256 minIncrement = _getMinIncrement(auction.amount);
        if (amount < minIncrement) {
          // If this bid outbids another, it must be at least 10% greater than the last bid.
          revert NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(minIncrement);
        }
      }

      // Cache and update bidder state
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      unchecked {
        // When a bid outbids another, check to see if a time extension should apply.
        // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
        // Current time plus extension duration (always 15 mins) cannot overflow.
        uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
        if (endTime < endTimeWithExtension) {
          endTime = endTimeWithExtension;
          auction.endTime = endTime;
        }
      }

      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    // Withdraw last in order to leverage freed METH balance.
    if (amount > msg.value) {
      // Withdraw additional ETH required from their available METH balance.

      unchecked {
        // The if above ensures delta will not underflow.
        // Withdraw ETH from the buyer's account in the METH token contract.
        METH.marketWithdrawFrom(msg.sender, amount - msg.value);
      }
    }

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, endTime);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the reservePrice may be
   * changed by the seller.
   * @param auctionId The id of the auction to change.
   * @param reservePrice The new reserve price for this auction.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external onlyValidAuctionConfig(reservePrice) {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    } else if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    } else if (auction.amount == reservePrice) {
      revert NFTMarketReserveAuction_Price_Already_Set();
    }

    // Update the current reserve price.
    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice Settle an auction that has already ended.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
   * redundant transfers if the NFT should remain in escrow, such as when the new owner
   * sets a buy price or lists it in a new auction.
   */
  function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow) private {
    ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];

    if (auction.endTime >= block.timestamp) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
    }

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!keepInEscrow) {
      // The seller was authorized when the auction was originally created
      super._transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder, address(0));
    }

    // Distribute revenue for this sale.
    (uint256 protocolFee, uint256 creatorFee, uint256 sellerRev) = _distributeFunds(
      auction.nftContract,
      auction.seller,
      auction.amount
    );

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, protocolFee, creatorFee, sellerRev);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev If an auction is found:
   *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
   *  - If the auction has not received a bid, it will invalidate the auction.
   *  - If the auction is in progress, this will revert.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual override {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0) {
      ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
      if (auction.endTime == 0) {
        // The auction has not received any bids yet so it may be invalided.

        if (authorizeSeller != address(0) && auction.seller != authorizeSeller) {
          // The account trying to transfer the NFT is not the current owner.
          revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
        delete auctionIdToAuction[auctionId];

        emit ReserveAuctionInvalidated(auctionId);
      } else {
        // If the auction has ended, the highest bidder will be the new owner
        // and if the auction is in progress, this will revert.

        // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
        // through this path to know who the authorized seller should be.
        if (auction.bidder != authorizeSeller) {
          revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
        }

        // Finalization will revert if the auction has not yet ended.
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is an auction for this NFT before allowing the transfer to continue.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    if (nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0) {
      // No auction was found

      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      // NFT is not in auction
      super._transferToEscrow(nftContract, tokenId);
      return;
    }
    // Using storage saves gas since most of the data is not needed
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      // Reserve price set, confirm the seller is a match
      if (auction.seller != msg.sender) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
      }
    } else {
      // Auction in progress, confirm the highest bidder is a match
      if (auction.bidder != msg.sender) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
      }

      // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
      _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
    }
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   * Bids must be greater than or equal to this value or they will revert.
   * @param auctionId The id of the auction to check.
   * @return minimum The minimum amount for a bid to be accepted.
   */
  function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
    ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

  /**
   * @notice Returns auction details for a given auctionId.
   * @param auctionId The id of the auction to lookup.
   */
  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
    ReserveAuctionStorage storage auctionStorage = auctionIdToAuction[auctionId];
    auction = ReserveAuction(
      auctionStorage.nftContract,
      auctionStorage.tokenId,
      auctionStorage.seller,
      DURATION,
      EXTENSION_DURATION,
      auctionStorage.endTime,
      auctionStorage.bidder,
      auctionStorage.amount
    );
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return auctionId The id of the auction, or 0 if no auction is found.
   */
  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256 auctionId) {
    auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }


  /**
   * @inheritdoc NFTMarketCore
   * @dev Returns the seller that has the given NFT in escrow for an auction,
   * or bubbles the call up for other considerations.
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
      seller = super._getSellerFor(nftContract, tokenId);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    return auctionId != 0 && auctionIdToAuction[auctionId].endTime >= block.timestamp;
  }

}

// File: contracts/MegaNFTMarket.sol


pragma solidity ^0.8.0;









/**
 * @title A market for NFTs on .
 * @notice The  marketplace is a contract which allows traders to buy and sell NFTs.
 * It supports buying and selling via auctions, private sales, buy price, and offers.
 * @dev All sales in the  market will pay the creator some % royalties on secondary sales. This is not specific
 * to NFTs minted on , it should work for any NFT. If royalty information was not defined when the NFT was
 * originally deployed, it may be added in our market contract which will be respected by our market contract.
 */
contract MegaNFTMarket is
  TreasuryNode,
  NFTMarketCore,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction,
  NFTMarketBuyPrice,
  NFTMarketOffer
{

  bool public initialized;

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param treasury The  Treasury contract address.
   * @param METH The METH ERC-20 token contract address.
   * @param duration The duration of the auction in seconds.
   */
  constructor(
    address payable treasury,
    address METH,
    uint256 duration
  )
    TreasuryNode(treasury)
    NFTMarketCore(METH)
    NFTMarketFees()
    NFTMarketReserveAuction(duration) 
  {
    
  }

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
   */
  function initialize() external  {
    require(initialized == false, "contract is already initialized");
    initialized = true;
    NFTMarketAuction._initializeNFTMarketAuction();
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketBuyPrice, NFTMarketOffer)
  {
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice) {
    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice) {
    super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
  {
    super._transferToEscrow(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
    returns (address payable seller)
  {
    seller = super._getSellerFor(nftContract, tokenId);
  }
}