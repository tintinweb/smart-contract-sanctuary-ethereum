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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

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
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import './interfaces/IJBProjectPayer.sol';
import './libraries/JBTokens.sol';

//*********************************************************************//
// -------------------------- custom errors -------------------------- //
//*********************************************************************//
error INSUFFICIENT_BALANCE();
error TERMINAL_NOT_FOUND();
error NO_MSG_VALUE_ALLOWED();

/** 
  @notice 
  A contract that sends funds to a project treasury via direct payments or contract calls.

  @dev
  Inherits from:
  IJBETHERC20ProjectPayerDeployer:  General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
  Ownable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
*/
contract JBETHERC20ProjectPayer is IJBProjectPayer, Ownable {
  /**
    @notice 
    A contract storing directories of terminals and controllers for each project.
  */
  IJBDirectory public immutable override directory;

  /** 
    @notice 
    The ID of the project that should be used to forward this contract's received payments.
  */
  uint256 public override defaultProjectId;

  /** 
    @notice 
    The beneficiary that should be used in the payment made when this contract receives payments.
  */
  address payable public override defaultBeneficiary;

  /** 
    @notice 
    A flag indicating whether issued tokens should be automatically claimed into the beneficiary's wallet. Leaving tokens unclaimed saves gas.
  */
  bool public override defaultPreferClaimedTokens;

  /** 
    @notice 
    The memo that should be used in the payment made when this contract receives payments.
  */
  string public override defaultMemo;

  /** 
    @notice 
    The metadata that should be used in the payment made when this contract receives payments.
  */
  bytes public override defaultMetadata;

  /** 
    @param _defaultProjectId The ID of the project that should be used to forward this contract's received payments.
    @param _defaultBeneficiary The address that'll receive the project's tokens. 
    @param _defaultPreferClaimedTokens A flag indicating whether issued tokens should be automatically claimed into the beneficiary's wallet. 
    @param _defaultMemo The memo that'll be used. 
    @param _defaultMetadata The metadata that'll be sent. 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  constructor(
    uint256 _defaultProjectId,
    address payable _defaultBeneficiary,
    bool _defaultPreferClaimedTokens,
    string memory _defaultMemo,
    bytes memory _defaultMetadata,
    IJBDirectory _directory,
    address _owner
  ) {
    directory = _directory;
    defaultProjectId = _defaultProjectId;
    defaultBeneficiary = _defaultBeneficiary;
    defaultPreferClaimedTokens = _defaultPreferClaimedTokens;
    defaultMemo = _defaultMemo;
    defaultMetadata = _defaultMetadata;

    _transferOwnership(_owner);
  }

  /** 
    Received funds go straight to the project.
  */
  receive() external payable virtual override {
    _pay(
      defaultProjectId,
      JBTokens.ETH,
      address(this).balance,
      defaultBeneficiary == address(0) ? msg.sender : defaultBeneficiary,
      0, // Can't determine expectation of returned tokens ahead of time.
      defaultPreferClaimedTokens,
      defaultMemo,
      defaultMetadata
    );
  }

  /** 
    @notice 
    Sets the default values that determin how to interact with a protocol treasury when this contract receives ETH directly.

    @param _projectId The ID of the project to forward funds to.
    @param _beneficiary The address that'll receive the project's tokens. 
    @param _preferClaimedTokens A flag indicating whether issued tokens should be automatically claimed into the beneficiary's wallet. 
    @param _memo The memo that'll be used. 
    @param _metadata The metadata that'll be sent. 
  */
  function setDefaultValues(
    uint256 _projectId,
    address payable _beneficiary,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) external override onlyOwner {
    if (_projectId != defaultProjectId) defaultProjectId = _projectId;
    if (_beneficiary != defaultBeneficiary) defaultBeneficiary = _beneficiary;
    if (_preferClaimedTokens != defaultPreferClaimedTokens)
      defaultPreferClaimedTokens = _preferClaimedTokens;
    if (keccak256(abi.encodePacked(_memo)) != keccak256(abi.encodePacked(defaultMemo)))
      defaultMemo = _memo;
    if (keccak256(abi.encodePacked(_metadata)) != keccak256(abi.encodePacked(defaultMetadata)))
      defaultMetadata = _metadata;
    emit SetDefaultValues(
      _projectId,
      _beneficiary,
      _preferClaimedTokens,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /** 
    @notice 
    Make a payment to this project.

    @param _projectId The ID of the project that is being paid.
    @param _token The token to pay in.
    @param _amount The amount of terminal tokens being received, as a fixed point number with the amount of decimals as the `_token`'s termina. If this terminal's token is ETH, this is ignored and msg.value is used in its place.
    @param _beneficiary The address who will receive tickets from this fee.
    @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point
    @param _preferClaimedTokens Whether ERC20's should be claimed automatically if they have been issued.
    @param _memo A memo that will be included in the published event.
    @param _metadata Bytes to send along with payments to the funding cycle's pay delegate.
  */
  function pay(
    uint256 _projectId,
    address _token,
    uint256 _amount,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) public payable virtual override {
    // ETH shouldn't be sent if this terminal's token isn't ETH.
    if (address(_token) != JBTokens.ETH) {
      if (msg.value > 0) revert NO_MSG_VALUE_ALLOWED();

      // Transfer tokens to this terminal from the msg sender.
      IERC20(_token).transferFrom(msg.sender, payable(address(this)), _amount);
    } else _amount = msg.value;

    _pay(
      _projectId,
      _token,
      _amount,
      _beneficiary,
      _minReturnedTokens,
      _preferClaimedTokens,
      _memo,
      _metadata
    );
  }

  /** 
    @notice 
    Pay a project.

    @param _projectId The ID of the project being funded.
    @param _token The token to pay in.
    @param _amount The payment amount.
    @param _beneficiary The address who will receive tickets from this fee.
    @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point
    @param _preferClaimedTokens Whether ERC20's should be claimed automatically if they have been issued.
    @param _memo A memo that will be included in the published event.
    @param _metadata Bytes to send along with payments to the funding cycle's data source and pay delegate.
  */
  function _pay(
    uint256 _projectId,
    address _token,
    uint256 _amount,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) internal virtual {
    // Find the terminal for this contract's project.
    IJBPaymentTerminal _terminal = directory.primaryTerminalOf(_projectId, _token);

    // There must be a terminal.
    if (_terminal == IJBPaymentTerminal(address(0))) revert TERMINAL_NOT_FOUND();

    // Approve the `_amount` of tokens from this terminal to transfer tokens from this terminal.
    if (_token != JBTokens.ETH) IERC20(_token).approve(address(_terminal), _amount);

    // If this terminal's token is ETH, send it in msg.value.
    uint256 _payableValue = _token == JBTokens.ETH ? _amount : 0;

    // Pay if there's a beneficiary to receive tokens.
    if (_beneficiary != address(0))
      // Send funds to the terminal.
      _terminal.pay{value: _payableValue}(
        _amount, // ignored if the token is JBTokens.ETH.
        _projectId,
        _beneficiary,
        _minReturnedTokens,
        _preferClaimedTokens,
        _memo,
        _metadata
      );
      // Otherwise just add to balance so tokens don't get issued.
    else _terminal.addToBalanceOf{value: _payableValue}(_projectId, _amount, _memo);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './interfaces/IJBETHERC20ProjectPayerDeployer.sol';

import './JBETHERC20ProjectPayer.sol';

/** 
  @notice 
  Deploys project payer contracts.

  @dev
  Inherits from:
  IJBETHERC20ProjectPayerDeployer:  General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
contract JBETHERC20ProjectPayerDeployer is IJBETHERC20ProjectPayerDeployer {
  /** 
    @notice 
    Allows anyone to deploy a new project payer contract.

    @param _defaultProjectId The ID of the project that should be used to forward the project payer's received payments.
    @param _defaultBeneficiary The address that'll receive the project's tokens when the project payer receives payments. 
    @param _defaultPreferClaimedTokens A flag indicating whether issued tokens from the project payer's received payments should be automatically claimed into the beneficiary's wallet. 
    @param _defaultMemo The memo that'll be forwarded with the project payer's received payments. 
    @param _defaultMetadata The metadata that'll be forwarded with the project payer's received payments. 
    @param _directory A contract storing directories of terminals and controllers for each project.

    @return projectPayer The project payer contract.
  */
  function deployProjectPayer(
    uint256 _defaultProjectId,
    address payable _defaultBeneficiary,
    bool _defaultPreferClaimedTokens,
    string memory _defaultMemo,
    bytes memory _defaultMetadata,
    IJBDirectory _directory,
    address _owner
  ) external override returns (IJBProjectPayer projectPayer) {
    // Deploy the project payer.
    projectPayer = new JBETHERC20ProjectPayer(
      _defaultProjectId,
      _defaultBeneficiary,
      _defaultPreferClaimedTokens,
      _defaultMemo,
      _defaultMetadata,
      _directory,
      _owner
    );

    emit DeployProjectPayer(
      projectPayer,
      _defaultProjectId,
      _defaultBeneficiary,
      _defaultPreferClaimedTokens,
      _defaultMemo,
      _defaultMetadata,
      _directory,
      _owner,
      msg.sender
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Approved,
  Active,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBProjectMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBDirectory.sol';
import './IJBToken.sol';
import './IJBPaymentTerminal.sol';
import './IJBFundingCycleStore.sol';
import './IJBTokenStore.sol';
import './IJBSplitsStore.sol';

interface IJBController {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBController to, address caller);

  event PrepMigration(uint256 indexed projectId, IJBController from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function issueTokenFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeTokenOf(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external;

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function prepForMigrationOf(uint256 _projectId, IJBController _from) external;

  function migrate(uint256 _projectId, IJBController _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';
import './IJBFundingCycleStore.sol';
import './IJBController.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, IJBController indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (IJBController);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, IJBController _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBProjectPayer.sol';

interface IJBETHERC20ProjectPayerDeployer {
  event DeployProjectPayer(
    IJBProjectPayer indexed projectPayer,
    uint256 indexed defaultProjectId,
    address indexed defaultBeneficiary,
    bool defaultPreferClaimedTokens,
    string defaultMemo,
    bytes defaultMetadata,
    IJBDirectory directory,
    address owner,
    address caller
  );

  function deployProjectPayer(
    uint256 _defaultProjectId,
    address payable _defaultBeneficiary,
    bool _defaultPreferClaimedTokens,
    string memory _defaultMemo,
    bytes memory _defaultMetadata,
    IJBDirectory _directory,
    address _owner
  ) external returns (IJBProjectPayer projectPayer);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function stateOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './IJBPayDelegate.sol';
import './IJBRedemptionDelegate.sol';

import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';

interface IJBFundingCycleDataSource {
  function payParams(JBPayParamsData calldata _data)
    external
    view
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    );

  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBDidPayData.sol';

interface IJBPayDelegate {
  function didPay(JBDidPayData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _amount,
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    string calldata _memo
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBProjectPayer {
  event SetDefaultValues(
    uint256 projectId,
    address beneficiary,
    bool preferClaimedTokens,
    string memo,
    bytes metadata,
    address caller
  );

  function directory() external view returns (IJBDirectory);

  function defaultProjectId() external view returns (uint256);

  function defaultBeneficiary() external view returns (address payable);

  function defaultPreferClaimedTokens() external view returns (bool);

  function defaultMemo() external view returns (string memory);

  function defaultMetadata() external view returns (bytes memory);

  function setDefaultValues(
    uint256 _projectId,
    address payable _beneficiary,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) external;

  function pay(
    uint256 _projectId,
    address _token,
    uint256 _amount,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) external payable;

  receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBPaymentTerminal.sol';
import './IJBTokenUriResolver.sol';

import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './../structs/JBDidRedeemData.sol';

interface IJBRedemptionDelegate {
  function didRedeem(JBDidRedeemData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '../structs/JBSplitAllocationData.sol';

interface IJBSplitAllocator {
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';
import './IJBProjects.sol';
import './IJBDirectory.sol';
import './IJBSplitAllocator.sol';

import './../structs/JBSplit.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBToken {
  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event Change(
    uint256 indexed projectId,
    IJBToken indexed newToken,
    IJBToken indexed oldToken,
    address owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeFor(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external returns (IJBToken oldToken);

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBSplitsGroups {
  uint256 public constant ETH_PAYOUT = 1;
  uint256 public constant RESERVED_TOKENS = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBTokens {
  /** 
    @notice 
    The ETH token address in Juicebox is represented by 0x000000000000000000000000000000000000EEEe.
  */
  address public constant ETH = address(0x000000000000000000000000000000000000EEEe);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

struct JBDidPayData {
  // The address from which the payment originated.
  address payer;
  // The ID of the project for which the payment was made.
  uint256 projectId;
  // The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount amount;
  // The number of project tokens minted for the beneficiary.
  uint256 projectTokenCount;
  // The address to which the tokens were minted.
  address beneficiary;
  // The memo that is being emitted alongside the payment.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

struct JBDidRedeemData {
  // The holder of the tokens being redeemed.
  address holder;
  // The project to which the redeemed tokens are associated.
  uint256 projectId;
  // The number of project tokens being redeemed.
  uint256 projectTokenCount;
  // The reclaimed amount. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount reclaimedAmount;
  // The address to which the reclaimed amount will be sent.
  address payable beneficiary;
  // The memo that is being emitted alongside the redemption.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

struct JBFundAccessConstraints {
  // The terminal within which the distribution limit and the overflow allowance applies.
  IJBPaymentTerminal terminal;
  // The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  uint256 distributionLimit;
  // The currency of the distribution limit.
  uint256 distributionLimitCurrency;
  // The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  uint256 overflowAllowance;
  // The currency of the overflow allowance.
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycle {
  // The funding cycle number for each project.
  // Each funding cycle has a number that is an increment of the cycle that directly preceded it.
  // Each project's first funding cycle has a number of 1.
  uint256 number;
  // The timestamp when the parameters for this funding cycle were configured.
  // This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  uint256 configuration;
  // The `configuration` of the funding cycle that was active when this cycle was created.
  uint256 basedOn;
  // The timestamp marking the moment from which the funding cycle is considered active.
  // It is a unix timestamp measured in seconds.
  uint256 start;
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
  // Extra data that can be associated with a funding cycle.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleDataSource.sol';

struct JBFundingCycleMetadata {
  // The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  uint256 reservedRate;
  // The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  uint256 redemptionRate;
  // The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  uint256 ballotRedemptionRate;
  // If the pay functionality should be paused during the funding cycle.
  bool pausePay;
  // If the distribute functionality should be paused during the funding cycle.
  bool pauseDistributions;
  // If the redeem functionality should be paused during the funding cycle.
  bool pauseRedeem;
  // If the mint functionality should be paused during the funding cycle.
  bool pauseMint;
  // If the burn functionality should be paused during the funding cycle.
  bool pauseBurn;
  // If changing tokens should be allowed during this funding cycle.
  bool allowChangeToken;
  // If migrating terminals should be allowed during this funding cycle.
  bool allowTerminalMigration;
  // If migrating controllers should be allowed during this funding cycle.
  bool allowControllerMigration;
  // If setting terminals should be allowed during this funding cycle.
  bool allowSetTerminals;
  // If setting a new controller should be allowed during this funding cycle.
  bool allowSetController;
  // If fees should be held during this funding cycle.
  bool holdFees;
  // If redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  bool useTotalOverflowForRedemptions;
  // If the data source should be used for pay transactions during this funding cycle.
  bool useDataSourceForPay;
  // If the data source should be used for redeem transactions during this funding cycle.
  bool useDataSourceForRedeem;
  // The data source to use during this funding cycle.
  IJBFundingCycleDataSource dataSource;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';
import '../libraries/JBSplitsGroups.sol';

struct JBGroupedSplits {
  // The group indentifier.
  uint256 group;
  // The splits to associate with the group.
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBOperatorData {
  // The address of the operator.
  address operator;
  // The domain within which the operator is being given permissions.
  // A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  uint256 domain;
  // The indexes of the permissions the operator is being given.
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

import './JBTokenAmount.sol';

struct JBPayParamsData {
  // The terminal that is facilitating the payment.
  IJBPaymentTerminal terminal;
  // The address from which the payment originated.
  address payer;
  // The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount amount;
  // The ID of the project being paid.
  uint256 projectId;
  // The weight of the funding cycle during which the payment is being made.
  uint256 weight;
  // The reserved rate of the funding cycle during which the payment is being made.
  uint256 reservedRate;
  // The memo that was sent alongside the payment.
  string memo;
  // Arbitrary metadata provided by the payer.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBProjectMetadata {
  // Metadata content.
  string content;
  // The domain within which the metadata applies.
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

struct JBRedeemParamsData {
  // The terminal that is facilitating the redemption.
  IJBPaymentTerminal terminal;
  // The holder of the tokens being redeemed.
  address holder;
  // The ID of the project whos tokens are being redeemed.
  uint256 projectId;
  // The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  uint256 tokenCount;
  // The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  uint256 totalSupply;
  // The amount of overflow used in the reclaim amount calculation.
  uint256 overflow;
  // The number of decimals included in the reclaim amount fixed point number.
  uint256 decimals;
  // The currency that the reclaim amount is expected to be in terms of.
  uint256 currency;
  // The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula.
  uint256 reclaimAmount;
  // If overflow across all of a project's terminals is being used when making redemptions.
  bool useTotalOverflow;
  // The redemption rate of the funding cycle during which the redemption is being made.
  uint256 redemptionRate;
  // The ballot redemption rate of the funding cycle during which the redemption is being made.
  uint256 ballotRedemptionRate;
  // The proposed memo that is being emitted alongside the redemption.
  string memo;
  // Arbitrary metadata provided by the redeemer.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

struct JBSplit {
  // A flag that only has effect if a projectId is also specified, and the project has a token contract attached.
  // If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  bool preferClaimed;
  // The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  uint256 percent;
  // If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified.
  // Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  uint256 projectId;
  // The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified.
  // If allocator is set, the beneficiary will be forwarded to the allocator for it to use.
  // If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it.
  // If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  address payable beneficiary;
  // Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  uint256 lockedUntil;
  // If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';
import './JBTokenAmount.sol';

struct JBSplitAllocationData {
  // The amount being sent to the split allocator, as a fixed point number.
  uint256 amount;
  // The number of decimals in the amount.
  uint256 decimals;
  // The project to which the split belongs.
  uint256 projectId;
  // The group to which the split belongs.
  uint256 group;
  // The split that caused the allocation.
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBTokenAmount {
  // The token the payment was made in.
  address token;
  // The amount of tokens that was paid, as a fixed point number.
  uint256 value;
  // The number of decimals included in the value fixed point number.
  uint256 decimals;
  // The expected currency of the value.
  uint256 currency;
}