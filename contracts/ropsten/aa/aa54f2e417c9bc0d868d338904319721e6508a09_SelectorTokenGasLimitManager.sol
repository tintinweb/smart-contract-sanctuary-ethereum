/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: contracts/interfaces/IAMB.sol

pragma solidity 0.7.5;

interface IAMB {
    event UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData);
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );
    event RelayedMessage(address indexed sender, address indexed executor, bytes32 indexed messageId, bool status);

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId) external view returns (address);

    function failedMessageSender(bytes32 _messageId) external view returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: contracts/upgradeable_contracts/modules/OwnableModule.sol

pragma solidity 0.7.5;

/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/upgradeability/EternalStorage.sol

pragma solidity 0.7.5;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

// File: contracts/upgradeable_contracts/Initializable.sol

pragma solidity 0.7.5;

contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }
}

// File: contracts/interfaces/IUpgradeabilityOwnerStorage.sol

pragma solidity 0.7.5;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// File: contracts/upgradeable_contracts/Upgradeable.sol

pragma solidity 0.7.5;

contract Upgradeable {
    /**
     * @dev Throws if called by any account other than the upgradeability owner.
     */
    modifier onlyIfUpgradeabilityOwner() {
        _onlyIfUpgradeabilityOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyIfUpgradeabilityOwner modifier bytecode overhead.
     */
    function _onlyIfUpgradeabilityOwner() internal view {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.7.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


pragma solidity ^0.7.0;

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts/upgradeable_contracts/Sacrifice.sol

pragma solidity 0.7.5;

contract Sacrifice {
    constructor(address payable _recipient) payable {
        selfdestruct(_recipient);
    }
}

// File: contracts/libraries/AddressHelper.sol

pragma solidity 0.7.5;

/**
 * @title AddressHelper
 * @dev Helper methods for Address type.
 */
library AddressHelper {
    /**
     * @dev Try to send native tokens to the address. If it fails, it will force the transfer by creating a selfdestruct contract
     * @param _receiver address that will receive the native tokens
     * @param _value the amount of native tokens to send
     */
    function safeSendValue(address payable _receiver, uint256 _value) internal {
        if (!(_receiver).send(_value)) {
            new Sacrifice{ value: _value }(_receiver);
        }
    }
}

// File: contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.7.5;




/**
 * @title Claimable
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable {
    using SafeERC20 for IERC20;

    /**
     * Throws if a given address is equal to address(0)
     */
    modifier validAddress(address _to) {
        require(_to != address(0));
        _;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) internal validAddress(_to) {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Withdraws the erc721 or erc1155 tokens from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token.
     * @param _to address of the tokens receiver.
     * @param _tokenIDs an array of token ids to transfer
     * @param _amounts an array of amounts by passed token ids
     * @param _isERC721 true if passed token ERC721, false - otherwise
     */
    function claimNFTs(
        address _token,
        address _to,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts,
        bool _isERC721
    ) internal validAddress(_to) {
        if (_isERC721) {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                IERC721(_token).transferFrom(address(this), _to, _tokenIDs[i]);
            }
        } else {
            IERC1155(_token).safeBatchTransferFrom(address(this), _to, _tokenIDs, _amounts, "");
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        AddressHelper.safeSendValue(payable(_to), value);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc20Tokens(address _token, address _to) internal {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }
}

// File: contracts/libraries/MultiChainHelper.sol

pragma solidity 0.7.5;

library MultiChainHelper {
    function currentChainID() internal pure returns (uint256 _currentChainID) {
        assembly {
            _currentChainID := chainid()
        }
    }

    function createSimpleKey(string memory _prefix, uint256 _chainID) internal pure returns (bytes32) {
        return createKey(_prefix, _chainID, new bytes(0));
    }

    function createAddressKey(
        string memory _prefix,
        uint256 _chainID,
        address _addr
    ) internal pure returns (bytes32) {
        return createKey(_prefix, _chainID, abi.encodePacked(_addr));
    }

    function createBytes32Key(
        string memory _prefix,
        uint256 _chainID,
        bytes32 _data
    ) internal pure returns (bytes32) {
        return createKey(_prefix, _chainID, abi.encodePacked(_data));
    }

    function createKey(
        string memory _prefix,
        uint256 _chainID,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return
            _data.length > 0
                ? keccak256(abi.encodePacked(_prefix, _chainID, "#", _data))
                : keccak256(abi.encodePacked(_prefix, _chainID));
    }
}

// File: contracts/upgradeable_contracts/components/bridged/BridgedTokensRegistry.sol

pragma solidity 0.7.5;


/**
 * @title BridgedTokensRegistry
 * @dev Functionality for keeping track of registered bridged token pairs.
 */
contract BridgedTokensRegistry is EternalStorage {
    event NewTokenRegistered(uint256 indexed chainID, address indexed homeToken, address indexed foreignToken);

    /**
     * @dev Retrieves address of the home token contract associated with a specific foreign token contract on the other side.
     * @param _chainID foreign token contract network id.
     * @param _foreignToken address of the foreign token contract on the other side.
     * @return address of the home token contract.
     */
    function homeToken(uint256 _chainID, address _foreignToken) public view returns (address) {
        return addressStorage[MultiChainHelper.createAddressKey("homeTokenAddress", _chainID, _foreignToken)];
    }

    /**
     * @dev Retrieves address of the foreign token contract associated with a specific home token contract.
     * @param _chainID foreign token contract network id.
     * @param _homeToken address of the home token contract.
     * @return address of the foreign token contract.
     */
    function foreignToken(uint256 _chainID, address _homeToken) public view returns (address) {
        return addressStorage[MultiChainHelper.createAddressKey("foreignTokenAddress", _chainID, _homeToken)];
    }

    /**
     * @dev Returns information about whether the token is native or not.
     * @param _homeToken address of the token contract on this side.
     */
    function isNative(address _homeToken) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("isNative", _homeToken))];
    }

    /**
     * @dev Internal function for updating a pair of addresses for the bridged token.
     * @param _chainID foreign token contract network id.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignToken address of the cbridged token contract on the other side.
     * @param _isHomeNative shows whether the home token is native
     */
    function _setTokenAddressPair(
        uint256 _chainID,
        address _homeToken,
        address _foreignToken,
        bool _isHomeNative
    ) internal {
        addressStorage[MultiChainHelper.createAddressKey("homeTokenAddress", _chainID, _foreignToken)] = _homeToken;
        addressStorage[MultiChainHelper.createAddressKey("foreignTokenAddress", _chainID, _homeToken)] = _foreignToken;

        boolStorage[keccak256(abi.encodePacked("isNative", _homeToken))] = _isHomeNative;

        emit NewTokenRegistered(_chainID, _homeToken, _foreignToken);
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


pragma solidity ^0.7.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: contracts/interfaces/IERC1155Receiver.sol


pragma solidity 0.7.5;

interface IERC1155Receiver {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/upgradeable_contracts/ReentrancyGuard.sol

pragma solidity 0.7.5;

contract ReentrancyGuard {
    function lock() internal view returns (bool res) {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            res := sload(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92) // keccak256(abi.encodePacked("lock"))
        }
    }

    function setLock(bool _lock) internal {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92, _lock) // keccak256(abi.encodePacked("lock"))
        }
    }
}

// File: contracts/upgradeable_contracts/Ownable.sol

pragma solidity 0.7.5;


/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyOwner modifier bytecode overhead.
     */
    function _onlyOwner() internal view {
        require(msg.sender == owner());
    }

    /**
     * @dev Throws if called through proxy by any account other than contract itself or an upgradeability owner.
     */
    modifier onlyRelevantSender() {
        (bool isProxy, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSelector(UPGRADEABILITY_OWNER)
        );
        require(
            !isProxy || // covers usage without calling through storage proxy
                (returnData.length == 32 && msg.sender == abi.decode(returnData, (address))) || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner the address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// File: contracts/upgradeable_contracts/BasicAMBMediator.sol

pragma solidity 0.7.5;




/**
 * @title BasicAMBMediator
 * @dev Basic storage and methods needed by mediators to interact with AMB bridge.
 */
abstract contract BasicAMBMediator is Ownable {
    /**
     * @dev Throws if caller on the other side is not an associated mediator.
     */
    modifier onlyMediator(uint256 _chainID) {
        _onlyMediator(_chainID);
        _;
    }

    /**
     * @dev Internal function for reducing onlyMediator modifier bytecode overhead.
     * @param _chainID specific network id.
     */
    function _onlyMediator(uint256 _chainID) internal view {
        IAMB bridge = bridgeContract(_chainID);
        require(msg.sender == address(bridge));
        require(bridge.messageSender() == mediatorContractOnOtherSide(_chainID));
    }

    /**
     * @dev Sets the AMB bridge contract address. Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _bridgeContract the address of the bridge contract.
     */
    function setBridgeContract(uint256 _chainID, address _bridgeContract) external onlyOwner {
        _setBridgeContract(_chainID, _bridgeContract);
    }

    /**
     * @dev Sets the mediator contract address from the other network. Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _mediatorContract the address of the mediator contract.
     */
    function setMediatorContractOnOtherSide(uint256 _chainID, address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_chainID, _mediatorContract);
    }

    /**
     * @dev Sets the bridge contract and mediator contract addresses. Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _bridgeContract the address of the bridge contract.
     * @param _mediatorContract the address of the mediator contract.
     */
    function setBridgeAndMediatorOnTheOtherSide(
        uint256 _chainID,
        address _bridgeContract,
        address _mediatorContract
    ) external onlyOwner {
        _setBridgeContract(_chainID, _bridgeContract);
        _setMediatorContractOnOtherSide(_chainID, _mediatorContract);
    }

    /**
     * @dev Tells if networks are supported by network id.
     * @param _chainID specific network id.
     * @return true - if supported, otherwise - false.
     */
    function isSupportedChain(uint256 _chainID) public view returns (bool) {
        return address(bridgeContract(_chainID)) != address(0) && mediatorContractOnOtherSide(_chainID) != address(0);
    }

    /**
     * @dev Get the AMB interface for the bridge contract address by network id.
     * @param _chainID specific network id.
     * @return AMB interface for the bridge contract address
     */
    function bridgeContract(uint256 _chainID) public view returns (IAMB) {
        return IAMB(addressStorage[MultiChainHelper.createSimpleKey("bridgeContract", _chainID)]);
    }

    /**
     * @dev Tells the mediator contract address from the other network by network id.
     * @param _chainID specific network id.
     * @return the address of the mediator contract.
     */
    function mediatorContractOnOtherSide(uint256 _chainID) public view returns (address) {
        return addressStorage[MultiChainHelper.createSimpleKey("mediatorContract", _chainID)];
    }

    /**
     * @dev Stores a valid AMB bridge contract address.
     * @param _chainID specific network id.
     * @param _bridgeContract the address of the bridge contract.
     */
    function _setBridgeContract(uint256 _chainID, address _bridgeContract) internal {
        require(Address.isContract(_bridgeContract));
        addressStorage[MultiChainHelper.createSimpleKey("bridgeContract", _chainID)] = _bridgeContract;
    }

    /**
     * @dev Stores the mediator contract address from the other network.
     * @param _chainID specific network id.
     * @param _mediatorContract the address of the mediator contract.
     */
    function _setMediatorContractOnOtherSide(uint256 _chainID, address _mediatorContract) internal {
        addressStorage[MultiChainHelper.createSimpleKey("mediatorContract", _chainID)] = _mediatorContract;
    }

    /**
     * @dev Tells the id of the message originated on the other network by network id.
     * @param _chainID specific network id.
     * @return the id of the message originated on the other network.
     */
    function messageId(uint256 _chainID) internal view returns (bytes32) {
        return bridgeContract(_chainID).messageId();
    }

    /**
     * @dev Tells the maximum gas limit that a message can use on its execution by the AMB bridge on the other network by network id.
     * @param _chainID specific network id.
     * @return the maximum gas limit value.
     */
    function maxGasPerTx(uint256 _chainID) internal view returns (uint256) {
        return bridgeContract(_chainID).maxGasPerTx();
    }

    function _passMessage(uint256 _chainID, bytes memory _data) internal virtual returns (bytes32);
}

// File: contracts/upgradeable_contracts/components/bridged/TokensTypeRegistry.sol

pragma solidity 0.7.5;

/**
 * @title TokensTypeRegistry
 * @dev Functionality for keeping track of bridged tokens types.
 */
contract TokensTypeRegistry is EternalStorage {
    /**
     * @dev Enumeration with token types.
     */
    enum TokensType {
        ERC721,
        ERC1155
    }

    /**
     * @dev Indicates whether the token is an ERC721 standard.
     * @param _token Specific token address.
     * @return true if passed token is ERC721, false - otherwise
     */
    function isERC721(address _token) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("isERC721", _token))];
    }

    /**
     @dev Internal function for setting the token type.
     @param _token Specific token address.
     @param _tokenType 0 - ERC721, 1 - ERC1155
     */
    function _setTokenType(address _token, TokensType _tokenType) internal {
        if (_tokenType == TokensType.ERC721) {
            boolStorage[keccak256(abi.encodePacked("isERC721", _token))] = true;
        }
    }
}

// File: contracts/upgradeable_contracts/components/common/TokensRelayer.sol

pragma solidity 0.7.5;









/**
 * @title TokensRelayer
 * @dev Functionality for bridging multiple tokens to the other side of the bridge.
 */
abstract contract TokensRelayer is
    BasicAMBMediator,
    TokensTypeRegistry,
    ReentrancyGuard,
    IERC721Receiver,
    IERC1155Receiver
{
    using SafeMath for uint256;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(lock(), "Unable to safe transfer token.");

        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(lock(), "Unable to safe transfer token.");

        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        require(lock(), "Unable to safe transfer tokens.");

        return 0xbc197c81;
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender.
     * The user should first call Approve method of the token.
     * @param _chainID destination network id.
     * @param _token home token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _tokenIDs an array of token IDs that are transferred between networks.
     * @param _amounts the number of tokens that are transferred between networks. If the token is ERC721, then all numbers must be equal to 1.
     */
    function relayTokens(
        uint256 _chainID,
        address _token,
        address _receiver,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) external {
        _relayTokens(_chainID, _token, _receiver, _tokenIDs, _amounts);
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender to msg.sender on the other side.
     * The user should first call Approve method of the token.
     * @param _chainID destination network id.
     * @param _token home token contract address.
     * @param _tokenIDs an array of token IDs that are transferred between networks.
     * @param _amounts the number of tokens that are transferred between networks. If the token is ERC721, then all numbers must be equal to 1.
     */
    function relayTokens(
        uint256 _chainID,
        address _token,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) external {
        _relayTokens(_chainID, _token, msg.sender, _tokenIDs, _amounts);
    }

    /**
     * @dev Validates that the token amount is inside the limits, calls safeTransferFrom to transfer the tokens to the contract
     * and invokes the method to burn/lock the tokens and unlock/mint the tokens on the other network.
     * The user should first call Approve method of the token.
     * @param _chainID destination network id.
     * @param _token bridge token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _tokenIDs an array of token IDs that are transferred between networks.
     * @param _amounts the number of tokens that are transferred between networks. If the token is ERC721, then all numbers must be equal to 1.
     */
    function _relayTokens(
        uint256 _chainID,
        address _token,
        address _receiver,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal {
        require(!lock(), "Already locked.");

        setLock(true);

        if (isERC721(_token)) {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                require(_amounts[i] == 1, "Incorrect amount.");

                IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenIDs[i]);
            }
        } else {
            IERC1155(_token).safeBatchTransferFrom(msg.sender, address(this), _tokenIDs, _amounts, "");
        }

        setLock(false);

        bridgeSpecificActionsOnTokenTransfer(_chainID, address(_token), msg.sender, _receiver, _tokenIDs, _amounts);
    }

    function bridgeSpecificActionsOnTokenTransfer(
        uint256 _chainID,
        address _token,
        address _from,
        address _receiver,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/VersionableBridge.sol

pragma solidity 0.7.5;

interface VersionableBridge {
    function getBridgeInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );

    function getBridgeMode() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/components/common/OmnibridgeInfo.sol

pragma solidity 0.7.5;

/**
 * @title OmnibridgeInfo
 * @dev Functionality for versioning Omnibridge mediator.
 */
contract OmnibridgeInfo is VersionableBridge {
    event TokensBridgingInitiated(
        uint256 chainID,
        address indexed token,
        address indexed sender,
        uint256[] tokenIDs,
        uint256[] amounts,
        bytes32 indexed messageId
    );
    event TokensBridged(
        uint256 chainID,
        address indexed token,
        address indexed recipient,
        uint256[] tokenIDs,
        uint256[] amounts,
        bytes32 indexed messageId
    );

    /**
     * @dev Tells the bridge interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getBridgeInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (3, 3, 0);
    }

    /**
     * @dev Tells the bridge mode that this contract supports.
     * @return _data 4 bytes representing the bridge mode
     */
    function getBridgeMode() external pure override returns (bytes4 _data) {
        return 0xb1516c26; // bytes4(keccak256(abi.encodePacked("multi-erc-to-erc-amb")))
    }
}

// File: contracts/upgradeable_contracts/components/common/TokensBridgeLimits.sol

pragma solidity 0.7.5;


/**
 * @title TokensBridgeLimits
 * @dev Functionality for keeping track of bridging limits for multiple tokens.
 */
contract TokensBridgeLimits is Ownable {
    using SafeMath for uint256;

    // token == 0x00..00 represents default limits (assuming decimals == 18) for all newly created tokens
    event TokenLimitsChanged(address indexed token, uint256 maxPerTx, uint256 minPerTx);
    event ExecutionTokenLimitChanged(address indexed token, uint256 newExecutionMaxPerTx);

    /**
     * @dev Checks if specified token was already bridged at least once.
     * @param _token address of the token contract.
     * @return true, if token address is address(0) or token was already bridged.
     */
    function isTokenRegistered(address _token) public view returns (bool) {
        return minPerTx(_token) > 0;
    }

    /**
     * @dev Retrieves current maximum amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return maximum amount on tokens that can be sent through the bridge in one transfer.
     */
    function maxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))];
    }

    /**
     * @dev Retrieves current maximum execution amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return maximum amount on tokens that can received from the bridge on the other side in one transaction.
     */
    function executionMaxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))];
    }

    /**
     * @dev Retrieves current minimum amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return minimum amount on tokens that can be sent through the bridge in one transfer.
     */
    function minPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minPerTx", _token))];
    }

    /**
     * @dev Checks that bridged amount of tokens conforms to the configured limits.
     * @param _token address of the token contract.
     * @param _amount amount of bridge tokens.
     * @return true, if specified amount can be bridged.
     */
    function withinLimit(address _token, uint256 _amount) public view returns (bool) {
        return _amount <= maxPerTx(_token) && _amount >= minPerTx(_token);
    }

    /**
     * @dev Checks that bridged amount of tokens conforms to the configured execution limits.
     * @param _token address of the token contract.
     * @param _amount amount of bridge tokens.
     * @return true, if specified amount can be processed and executed.
     */
    function withinExecutionLimit(address _token, uint256 _amount) public view returns (bool) {
        return _amount <= executionMaxPerTx(_token);
    }

    /**
     * @dev Updates execution maximum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _maxPerTx maximum amount of executed tokens per one transaction, should be less than executionDailyLimit.
     * 0 value is also allowed, will stop the bridge operations in incoming direction.
     */
    function setExecutionMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _maxPerTx;
    }

    /**
     * @dev Updates maximum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _maxPerTx maximum amount of tokens per one transaction, should be less than dailyLimit, greater than minPerTx.
     * 0 value is also allowed, will stop the bridge operations in outgoing direction.
     */
    function setMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || _maxPerTx > minPerTx(_token));
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _maxPerTx;
    }

    /**
     * @dev Updates minimum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _minPerTx minimum amount of tokens per one transaction, should be less than maxPerTx and dailyLimit.
     */
    function setMinPerTx(address _token, uint256 _minPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_minPerTx > 0 && _minPerTx < maxPerTx(_token));
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _minPerTx;
    }

    /**
     * @dev Internal function for initializing limits for some token.
     * @param _token address of the token contract.
     * @param _limits [ 0 = maxPerTx, 1 = minPerTx ].
     */
    function _setLimits(address _token, uint256[2] memory _limits) internal {
        require(
            _limits[1] > 0 && // minPerTx > 0
                _limits[0] > _limits[1] // maxPerTx > minPerTx
        );

        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _limits[1];

        emit TokenLimitsChanged(_token, _limits[0], _limits[1]);
    }

    /**
     * @dev Internal function for initializing execution limits for some token.
     * @param _token address of the token contract.
     * @param _maxPerTx max execution token ids per tx.
     */
    function _setExecutionMaxPerTx(address _token, uint256 _maxPerTx) internal {
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _maxPerTx;

        emit ExecutionTokenLimitChanged(_token, _maxPerTx);
    }

    /**
     * @dev Internal function for initializing limits for some token relative to its decimals parameter.
     * @param _token address of the token contract.
     * @param _decimals token decimals parameter.
     */
    function _initializeTokenBridgeLimits(address _token, uint256 _decimals) internal {
        uint256 factor;
        if (_decimals < 18) {
            factor = 10**(18 - _decimals);

            uint256 _minPerTx = minPerTx(address(0)).div(factor);
            uint256 _maxPerTx = maxPerTx(address(0)).div(factor);
            uint256 _executionMaxPerTx = executionMaxPerTx(address(0)).div(factor);

            // such situation can happen when calculated limits relative to the token decimals are too low
            // e.g. minPerTx(address(0)) == 10 ** 14, _decimals == 3. _minPerTx happens to be 0, which is not allowed.
            // in this case, limits are raised to the default values
            if (_minPerTx == 0) {
                // Numbers 1, 100, 10000 are chosen in a semi-random way,
                // so that any token with small decimals can still be bridged in some amounts.
                // It is possible to override limits for the particular token later if needed.
                _minPerTx = 1;
                if (_maxPerTx <= _minPerTx) {
                    _maxPerTx = 100;
                    _executionMaxPerTx = 100;
                }
            }
            _setLimits(_token, [_maxPerTx, _minPerTx]);
            _setExecutionMaxPerTx(_token, _executionMaxPerTx);
        } else {
            factor = 10**(_decimals - 18);
            _setLimits(_token, [maxPerTx(address(0)).mul(factor), minPerTx(address(0)).mul(factor)]);
            _setExecutionMaxPerTx(_token, executionMaxPerTx(address(0)).mul(factor));
        }
    }
}

// File: contracts/upgradeable_contracts/components/common/BridgeOperationsStorage.sol

pragma solidity 0.7.5;


/**
 * @title BridgeOperationsStorage
 * @dev Functionality for storing processed bridged operations.
 */
abstract contract BridgeOperationsStorage is TokensTypeRegistry {
    /**
     * @dev Stores the bridged token of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _token bridged token address.
     */
    function _setMessageToken(
        uint256 _chainID,
        bytes32 _messageId,
        address _token
    ) internal {
        addressStorage[MultiChainHelper.createBytes32Key("messageToken", _chainID, _messageId)] = _token;
    }

    /**
     * @dev Tells the bridged token address of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return address of a token contract.
     */
    function messageToken(uint256 _chainID, bytes32 _messageId) internal view returns (address) {
        return addressStorage[MultiChainHelper.createBytes32Key("messageToken", _chainID, _messageId)];
    }

    /**
     * @dev Stores the receiver of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _recipient receiver of the tokens bridged.
     */
    function _setMessageRecipient(
        uint256 _chainID,
        bytes32 _messageId,
        address _recipient
    ) internal {
        addressStorage[MultiChainHelper.createBytes32Key("messageRecipient", _chainID, _messageId)] = _recipient;
    }

    /**
     * @dev Tells the receiver of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return address of the receiver.
     */
    function messageRecipient(uint256 _chainID, bytes32 _messageId) internal view returns (address) {
        return addressStorage[MultiChainHelper.createBytes32Key("messageRecipient", _chainID, _messageId)];
    }

    /**
     * @dev Internal function that saves message values to be able to return tokens in case of an unsuccessful bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _tokenIDs an array of token IDs that are transferred between networks.
     * @param _amounts the number of tokens that are transferred between networks. If the token is ERC721, then all numbers must be equal to 1.
     */
    function _setMessageValues(
        uint256 _chainID,
        bytes32 _messageId,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal {
        require(_tokenIDs.length > 0, "Zero token ids array");

        uintStorage[MultiChainHelper.createBytes32Key("messageTokensCount", _chainID, _messageId)] = _tokenIDs.length;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uintStorage[keccak256(abi.encodePacked("messageTokenIDs", _chainID, "#", _messageId, "#", i))] = _tokenIDs[
                i
            ];
        }

        if (!isERC721(messageToken(_chainID, _messageId))) {
            for (uint256 i = 0; i < _amounts.length; i++) {
                uintStorage[
                    keccak256(abi.encodePacked("messageTokenAmounts", _chainID, "#", _messageId, "#", i))
                ] = _amounts[i];
            }
        }
    }

    /**
     * @dev Returns the number of token IDs that have been translated for a particular message.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return the number of token IDs
     */
    function messageTokensCount(uint256 _chainID, bytes32 _messageId) public view returns (uint256) {
        return uintStorage[MultiChainHelper.createBytes32Key("messageTokensCount", _chainID, _messageId)];
    }

    /**
     * @dev Returns the token ids and amounts arrays for a particular message.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return _tokenIDs an array of token IDs
     * @return _amounts an array of token amounts for each identifier. Maximum equal to 1 if ERC721
     */
    function messageValues(uint256 _chainID, bytes32 _messageId)
        public
        view
        returns (uint256[] memory _tokenIDs, uint256[] memory _amounts)
    {
        uint256 _tokensCount = messageTokensCount(_chainID, _messageId);
        bool _isERC721 = isERC721(messageToken(_chainID, _messageId));

        _tokenIDs = new uint256[](_tokensCount);
        _amounts = new uint256[](_tokensCount);

        for (uint256 i = 0; i < _tokensCount; i++) {
            _tokenIDs[i] = uintStorage[
                keccak256(abi.encodePacked("messageTokenIDs", _chainID, "#", _messageId, "#", i))
            ];
            if (_isERC721) {
                _amounts[i] = 1;
            } else {
                _amounts[i] = uintStorage[
                    keccak256(abi.encodePacked("messageTokenAmounts", _chainID, "#", _messageId, "#", i))
                ];
            }
        }
    }
}

// File: contracts/upgradeable_contracts/components/common/FailedMessagesProcessor.sol

pragma solidity 0.7.5;


/**
 * @title FailedMessagesProcessor
 * @dev Functionality for fixing failed bridging operations.
 */
abstract contract FailedMessagesProcessor is BasicAMBMediator, BridgeOperationsStorage {
    event FailedMessageFixed(
        uint256 indexed chainID,
        bytes32 indexed messageId,
        address token,
        address recipient,
        uint256[] tokenIDs,
        uint256[] amounts
    );

    /**
     * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
     * fix/roll back the transferred assets on the other network.
     * @param _chainID required network id.
     * @param _messageId id of the message which execution failed.
     */
    function requestFailedMessageFix(uint256 _chainID, bytes32 _messageId) external {
        IAMB bridge = bridgeContract(_chainID);
        require(!bridge.messageCallStatus(_messageId));
        require(bridge.failedMessageReceiver(_messageId) == address(this));
        require(bridge.failedMessageSender(_messageId) == mediatorContractOnOtherSide(_chainID));

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, MultiChainHelper.currentChainID(), _messageId);

        _passMessage(_chainID, data);
    }

    /**
     * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
     * It uses the information stored by passMessage method when the assets were initially transferred
     * @param _chainID other network id.
     * @param _messageId id of the message which execution failed on the other network.
     */
    function fixFailedMessage(uint256 _chainID, bytes32 _messageId) public onlyMediator(_chainID) {
        require(!messageFixed(_chainID, _messageId));

        address token = messageToken(_chainID, _messageId);
        address recipient = messageRecipient(_chainID, _messageId);
        (uint256[] memory tokenIDs, uint256[] memory amounts) = messageValues(_chainID, _messageId);

        setMessageFixed(_chainID, _messageId);
        executeActionOnFixedTokens(token, recipient, tokenIDs, amounts);

        emit FailedMessageFixed(_chainID, _messageId, token, recipient, tokenIDs, amounts);
    }

    /**
     * @dev Tells if a message sent to the AMB bridge has been fixed.
     * @param _chainID required network id.
     * @param _messageId of the message sent to the bridge.
     * @return bool indicating the status of the message.
     */
    function messageFixed(uint256 _chainID, bytes32 _messageId) public view returns (bool) {
        return boolStorage[MultiChainHelper.createBytes32Key("messageFixed", _chainID, _messageId)];
    }

    /**
     * @dev Sets that the message sent to the AMB bridge has been fixed.
     * @param _chainID required network id.
     * @param _messageId of the message sent to the bridge.
     */
    function setMessageFixed(uint256 _chainID, bytes32 _messageId) internal {
        boolStorage[MultiChainHelper.createBytes32Key("messageFixed", _chainID, _messageId)] = true;
    }

    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIDs,
        uint256[] memory _amounts
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/components/native/MediatorBalanceStorage.sol

pragma solidity 0.7.5;



/**
 * @title MediatorBalanceStorage
 * @dev Functionality for storing expected mediator balance for native tokens.
 */
contract MediatorBalanceStorage is TokensTypeRegistry {
    /**
     * @dev Tells the expected token balance of the contract by token id.
     * @param _token address of token contract.
     * @param _tokenID specific token id
     * @return the current tracked token balance of the contract by token id.
     */
    function mediatorBalance(address _token, uint256 _tokenID) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token, "#", _tokenID))];
    }

    /**
     * @dev Tells the expected token balances of the contract by token ids.
     * @param _token address of token contract.
     * @param _tokenIDs an array of specific token ids.
     * @return _amounts Array of mediator balances by passed identifiers.
     */
    function mediatorBalances(address _token, uint256[] memory _tokenIDs)
        public
        view
        returns (uint256[] memory _amounts)
    {
        _amounts = new uint256[](_tokenIDs.length);

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _amounts[i] = uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token, "#", _tokenIDs[i]))];
        }
    }

    /**
     * @dev Updates expected token balance of the contract.
     * @param _token address of token contract.
     * @param _balance the new token balance of the contract.
     */
    function _setMediatorBalance(
        address _token,
        uint256 _tokenID,
        uint256 _balance
    ) internal {
        uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token, "#", _tokenID))] = _balance;
    }

    /**
     * @dev Updates expected token balances of the contract by token ids.
     * @param _token address of token contract.
     * @param _tokenIDs an array of specific token ids.
     * @param _amounts an array of amounts by passed token ids. If token is ERC721, all amounts must be equal to 1.
     * @param _isAdding true for adding amounts, false - otherwise
     */
    function _updateMediatorBalances(
        address _token,
        uint256[] memory _tokenIDs,
        uint256[] memory _amounts,
        bool _isAdding
    ) internal {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _currentAmount = uintStorage[
                keccak256(abi.encodePacked("mediatorBalance", _token, "#", _tokenIDs[i]))
            ];

            uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token, "#", _tokenIDs[i]))] = _isAdding
                ? _currentAmount + _amounts[i]
                : _currentAmount - _amounts[i];
        }
    }
}

// File: contracts/interfaces/IBurnableMintableERC721Token.sol

pragma solidity 0.7.5;

interface IBurnableMintableERC721Token {
    function mint(address _to, uint256[] calldata _tokenIDs) external;

    function burn(uint256[] calldata _tokenIDs) external;
}

// File: contracts/interfaces/IBurnableMintableERC1155Token.sol

pragma solidity 0.7.5;

interface IBurnableMintableERC1155Token {
    function mint(
        address _to,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _values
    ) external;

    function burn(uint256[] calldata _tokenIDs, uint256[] calldata _values) external;
}

// File: contracts/libraries/TokenReader.sol

pragma solidity 0.7.5;

// solhint-disable
interface ITokenDetails {
    function name() external view;

    function NAME() external view;

    function symbol() external view;

    function SYMBOL() external view;

    function decimals() external view;

    function DECIMALS() external view;
}

// solhint-enable

/**
 * @title TokenReader
 * @dev Helper methods for reading name/symbol/decimals parameters from ERC20 token contracts.
 */
library TokenReader {
    /**
     * @dev Reads the name property of the provided token.
     * Either name() or NAME() method is used.
     * Both, string and bytes32 types are supported.
     * @param _token address of the token contract.
     * @return token name as a string or an empty string if none of the methods succeeded.
     */
    function readName(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.name.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.NAME.selector));
            if (!status) {
                return "";
            }
        }
        return _convertToString(data);
    }

    /**
     * @dev Reads the symbol property of the provided token.
     * Either symbol() or SYMBOL() method is used.
     * Both, string and bytes32 types are supported.
     * @param _token address of the token contract.
     * @return token symbol as a string or an empty string if none of the methods succeeded.
     */
    function readSymbol(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.symbol.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.SYMBOL.selector));
            if (!status) {
                return "";
            }
        }
        return _convertToString(data);
    }

    /**
     * @dev Reads the decimals property of the provided token.
     * Either decimals() or DECIMALS() method is used.
     * @param _token address of the token contract.
     * @return token decimals or 0 if none of the methods succeeded.
     */
    function readDecimals(address _token) internal view returns (uint8) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.decimals.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.DECIMALS.selector));
            if (!status) {
                return 0;
            }
        }
        return abi.decode(data, (uint8));
    }

    /**
     * @dev Internal function for converting returned value of name()/symbol() from bytes32/string to string.
     * @param returnData data returned by the token contract.
     * @return string with value obtained from returnData.
     */
    function _convertToString(bytes memory returnData) private pure returns (string memory) {
        if (returnData.length > 32) {
            return abi.decode(returnData, (string));
        } else if (returnData.length == 32) {
            bytes32 data = abi.decode(returnData, (bytes32));
            string memory res = new string(32);
            assembly {
                let len := 0
                mstore(add(res, 32), data) // save value in result string

                // solhint-disable
                for {

                } gt(data, 0) {
                    len := add(len, 1)
                } {
                    // until string is empty
                    data := shl(8, data) // shift left by one symbol
                }
                // solhint-enable
                mstore(res, len) // save result string length
            }
            return res;
        } else {
            return "";
        }
    }
}

// File: contracts/upgradeable_contracts/BasicOmnibridge.sol

pragma solidity 0.7.5;















/**
 * @title BasicOmnibridge
 * @dev Common functionality for multi-token mediator intended to work on top of AMB bridge.
 */
abstract contract BasicOmnibridge is
    Initializable,
    Upgradeable,
    Claimable,
    OmnibridgeInfo,
    TokensRelayer,
    BridgedTokensRegistry,
    FailedMessagesProcessor,
    MediatorBalanceStorage,
    TokensBridgeLimits
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * @param _chainID network id on the other side.
     * @param _token address of the native ERC20 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIDs an array of token ids to handle.
     * @param _amounts an array of amounts by passed token ids.
     */
    function handleBridgedTokens(
        uint256 _chainID,
        address _token,
        address _recipient,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) external onlyMediator(_chainID) {
        address token = homeToken(_chainID, _token);

        require(isTokenRegistered(token));

        _handleTokens(_chainID, token, _recipient, _tokenIDs, _amounts);
    }

    /**
     * @dev Unlock back the amount of tokens that were bridged to the other network but failed.
     * @param _token address that bridged token contract.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIDs an array of token ids.
     * @param _amounts an array of amounts by passed token ids.
     */
    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIDs,
        uint256[] memory _amounts
    ) internal override {
        _releaseTokens(_token, _recipient, _tokenIDs, _amounts);
    }

    /**
     * @dev Used to set one token pairs for specific networks and initialize limits.
     * Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignToken address of the token contract on the other side.
     * @param _isHomeNative shows whether the home token is native.
     * @param _tokenType 0 - ERC721, 1 - ERC1155
     */
    function setTokensPair(
        uint256 _chainID,
        address _homeToken,
        address _foreignToken,
        bool _isHomeNative,
        TokensType _tokenType
    ) external onlyOwner {
        _setTokensPair(_chainID, _homeToken, _foreignToken, _isHomeNative, _tokenType);
    }

    /**
     * @dev Used to set many token pairs for single home token for specific networks and initialize limits.
     * Only the owner can call this method.
     * @param _chainIDs array of specific network ids.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignTokens array of addresses of the token contracts on the other side.
     * @param _isHomeNative shows whether the home token is native.
     * @param _tokenType 0 - ERC721, 1 - ERC1155
     */
    function setTokensPairBatch(
        uint256[] memory _chainIDs,
        address _homeToken,
        address[] memory _foreignTokens,
        bool _isHomeNative,
        TokensType _tokenType
    ) external onlyOwner {
        require(_chainIDs.length == _foreignTokens.length, "Lengths mismatch.");

        for (uint256 i = 0; i < _chainIDs.length; i++) {
            _setTokensPair(_chainIDs[i], _homeToken, _foreignTokens[i], _isHomeNative, _tokenType);
        }
    }

    /**
     * @dev Allows to send to the other network the amount of locked tokens that can be forced into the contract
     * without the invocation of the required methods. (e. g. regular transfer without a call to onTokenTransfer)
     * @param _chainID specific network id.
     * @param _token address of the token contract.
     * @param _receiver the address that will receive the tokens on the other network.
     * @param _tokenIDs an array of unaccounted token ids.
     * @param _amounts an array of amounts by passed token ids. If token is ERC721 all amounts must be equal to 1.
     */
    function fixMediatorBalance(
        uint256 _chainID,
        address _token,
        address _receiver,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) external onlyIfUpgradeabilityOwner validAddress(_receiver) {
        require(_tokenIDs.length == _amounts.length, "Length mismatch.");
        require(_isUnaccountedTokens(_token, _tokenIDs, _amounts), "Incorrect unaccounted token ids array.");
        require(withinLimit(_token, _tokenIDs.length), "Out of limits.");

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIDs, _amounts);
        bytes32 _messageId = _passMessage(_chainID, data);
        _recordBridgeOperation(_chainID, _messageId, _token, _receiver, _tokenIDs, _amounts);
    }

    /**
     * @dev Claims stuck tokens. Only unsupported tokens can be claimed.
     * When dealing with already supported tokens, fixMediatorBalance can be used instead.
     * @param _token address of claimed token, address(0) for native
     * @param _to address of tokens receiver
     */
    function claimERC20Tokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        // Only unregistered tokens and native coins are allowed to be claimed with the use of this function
        require(_token == address(0) || !isTokenRegistered(_token));
        claimValues(_token, _to);
    }

    /**
     * @dev Claims stuck tokens. Only unsupported tokens can be claimed.
     * When dealing with already supported tokens, fixMediatorBalance can be used instead.
     * @param _token address of claimed token
     * @param _to address of tokens receiver
     * @param _tokenIDs an array of token ids to transfer
     * @param _amounts an array of amounts by passed token ids
     * @param _isERC721 true if passed token ERC721, false - otherwise
     */
    function claimUnregisteredNFTs(
        address _token,
        address _to,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts,
        bool _isERC721
    ) external onlyIfUpgradeabilityOwner {
        // Only unregistered tokens and native coins are allowed to be claimed with the use of this function
        require(!isTokenRegistered(_token));

        claimNFTs(_token, _to, _tokenIDs, _amounts, _isERC721);
    }

    /**
     * @dev Internal function for setting token pair for further usage.
     * @param _chainID specific network id.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignToken address of the token contract on the other side.
     * @param _isHomeNative shows whether the home token is native.
     * @param _tokenType 0 - ERC721, 1 - ERC1155
     */
    function _setTokensPair(
        uint256 _chainID,
        address _homeToken,
        address _foreignToken,
        bool _isHomeNative,
        TokensType _tokenType
    ) internal {
        require(!isTokenRegistered(_foreignToken));
        require(homeToken(_chainID, _foreignToken) == address(0));
        require(foreignToken(_chainID, _homeToken) == address(0));

        _setTokenAddressPair(_chainID, _homeToken, _foreignToken, _isHomeNative);
        _setTokenType(_homeToken, _tokenType);

        if (!isTokenRegistered(_homeToken)) {
            _initializeTokenBridgeLimits(_homeToken, TokenReader.readDecimals(_homeToken));
        }
    }

    /**
     * @dev Internal function for recording bridge operation for further usage.
     * Recorded information is used for fixing failed requests on the other side.
     * @param _chainID network id on the other side.
     * @param _messageId id of the sent message.
     * @param _token bridged token address.
     * @param _sender address of the tokens sender.
     * @param _tokenIDs an array of token ids to save.
     * @param _amounts an array of amounts to save by passed token ids.
     */
    function _recordBridgeOperation(
        uint256 _chainID,
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal {
        _setMessageToken(_chainID, _messageId, _token);
        _setMessageRecipient(_chainID, _messageId, _sender);
        _setMessageValues(_chainID, _messageId, _tokenIDs, _amounts);

        emit TokensBridgingInitiated(_chainID, _token, _sender, _tokenIDs, _amounts, _messageId);
    }

    /**
     * @dev Constructs the message to be sent to the other side. Burns/locks bridged amount of tokens.
     * @param _token bridged token address.
     * @param _receiver address of the tokens receiver on the other side.
     * @param _tokenIDs an array of token ids to transfer/burn.
     * @param _amounts an array of amounts by passed token ids.
     */
    function _prepareMessage(
        address _token,
        address _receiver,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal returns (bytes memory) {
        if (!isNative(_token)) {
            if (isERC721(_token)) {
                IBurnableMintableERC721Token(_token).burn(_tokenIDs);
            } else {
                IBurnableMintableERC1155Token(_token).burn(_tokenIDs, _amounts);
            }
        } else {
            _updateMediatorBalances(_token, _tokenIDs, _amounts, true);
        }

        return
            abi.encodeWithSelector(
                this.handleBridgedTokens.selector,
                MultiChainHelper.currentChainID(),
                _token,
                _receiver,
                _tokenIDs,
                _amounts
            );
    }

    /**
     * Internal function for unlocking/mint some amount of tokens.
     * @param _token address of the token contract.
     * @param _recipient address of the tokens receiver.
     * @param _tokenIDs an array of token ids to transfer/mint.
     * @param _amounts an array of amounts by passed token ids.
     */
    function _releaseTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIDs,
        uint256[] memory _amounts
    ) internal {
        bool _isERC721 = isERC721(_token);

        if (isNative(_token)) {
            if (_isERC721) {
                for (uint256 i = 0; i < _tokenIDs.length; i++) {
                    require(_amounts[i] == 1, "Incorrect amount.");

                    IERC721(_token).safeTransferFrom(address(this), _recipient, _tokenIDs[i]);
                }
            } else {
                IERC1155(_token).safeBatchTransferFrom(address(this), _recipient, _tokenIDs, _amounts, "");
            }
            _updateMediatorBalances(_token, _tokenIDs, _amounts, false);
        } else {
            if (_isERC721) {
                IBurnableMintableERC721Token(_token).mint(_recipient, _tokenIDs);
            } else {
                IBurnableMintableERC1155Token(_token).mint(_recipient, _tokenIDs, _amounts);
            }
        }
    }

    /**
     * @dev Internal function to verify that the passed arrays of token identifiers are unaccounted.
     * @param _token address of the token contract.
     * @param _tokenIDs an array of specific token ids.
     * @param _amounts an array of token amounts by token ids.
     * @return true if passed token ids and amounts are unaccounted.
     */
    function _isUnaccountedTokens(
        address _token,
        uint256[] memory _tokenIDs,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        if (isERC721(_token)) {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                if (mediatorBalance(_token, _tokenIDs[i]) > 0 || _amounts[i] != 1) {
                    return false;
                }
            }
        } else {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                if (
                    IERC1155(_token).balanceOf(address(this), _tokenIDs[i]) - mediatorBalance(_token, _tokenIDs[i]) <
                    _amounts[i]
                ) {
                    return false;
                }
            }
        }

        return true;
    }

    function _handleTokens(
        uint256 _chainID,
        address _token,
        address _recipient,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/modules/gas_limit/SelectorTokenGasLimitManager.sol

pragma solidity 0.7.5;



/**
 * @title SelectorTokenGasLimitManager
 * @dev Multi token mediator functionality for managing request gas limits.
 */
contract SelectorTokenGasLimitManager is OwnableModule {
    // chainID => bridge address
    mapping(uint256 => IAMB) internal bridges;
    mapping(uint256 => uint256) internal defaultGasLimits;
    mapping(uint256 => mapping(bytes4 => uint256)) internal selectorGasLimit;
    mapping(uint256 => mapping(bytes4 => mapping(address => uint256))) internal selectorTokenGasLimit;

    constructor(
        uint256[] memory _chainIDs,
        IAMB[] memory _bridges,
        address _owner,
        uint256[] memory _gasLimits
    ) OwnableModule(_owner) {
        require(_chainIDs.length == _bridges.length && _chainIDs.length == _gasLimits.length, "Lengths mismatch.");

        for (uint256 i = 0; i < _chainIDs.length; i++) {
            _setBridgeContract(_chainIDs[i], _bridges[i], _gasLimits[i]);
        }
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Throws if provided gas limit is greater then the maximum allowed gas limit in the AMB contract.
     * @param _gasLimit gas limit value to check.
     */
    modifier validGasLimit(uint256 _chainID, uint256 _gasLimit) {
        require(_gasLimit <= bridges[_chainID].maxGasPerTx());
        _;
    }

    /**
     * @dev Throws if one of the provided gas limits is greater then the maximum allowed gas limit in the AMB contract.
     * @param _length expected length of the _gasLimits array.
     * @param _gasLimits array of gas limit values to check, should contain exactly _length elements.
     */
    modifier validGasLimits(
        uint256 _chainID,
        uint256 _length,
        uint256[] calldata _gasLimits
    ) {
        _validGasLimits(_chainID, _length, _gasLimits);
        _;
    }

    /**
     * @dev Sets the bridge contract and default gas limit for the specific network id.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _bridgeContract address of the bridge contract on the Home side.
     * @param _defaultGasLimit default gas limit
     */
    function setBridgeContract(
        uint256 _chainID,
        IAMB _bridgeContract,
        uint256 _defaultGasLimit
    ) external onlyOwner {
        _setBridgeContract(_chainID, _bridgeContract, _defaultGasLimit);
    }

    /**
     * @dev Sets the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(uint256 _chainID, uint256 _gasLimit)
        external
        onlyOwner
        validGasLimit(_chainID, _gasLimit)
    {
        defaultGasLimits[_chainID] = _gasLimit;
    }

    /**
     * @dev Sets the selector-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _selector method selector of the outgoing message payload.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(
        uint256 _chainID,
        bytes4 _selector,
        uint256 _gasLimit
    ) external onlyOwner validGasLimit(_chainID, _gasLimit) {
        selectorGasLimit[_chainID][_selector] = _gasLimit;
    }

    /**
     * @dev Sets the token-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _selector method selector of the outgoing message payload.
     * @param _token address of the native token that is used in the first argument of handleBridgedTokens/handleNativeTokens.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(
        uint256 _chainID,
        bytes4 _selector,
        address _token,
        uint256 _gasLimit
    ) external onlyOwner validGasLimit(_chainID, _gasLimit) {
        selectorTokenGasLimit[_chainID][_selector][_token] = _gasLimit;
    }

    /**
     * @dev Tells if the manager supports the required network.
     * @param _chainID required network id.
     * @return true - if supports, otherwise false.
     */
    function isNetworkExists(uint256 _chainID) public view returns (bool) {
        return address(bridges[_chainID]) != address(0);
    }

    /**
     * @dev Returns bridge contract address by network id.
     * @param _chainID required network id.
     * @return the bridge contract.
     */
    function bridgeContract(uint256 _chainID) public view returns (IAMB) {
        return bridges[_chainID];
    }

    /**
     * @dev Tells the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(uint256 _chainID) public view returns (uint256) {
        return defaultGasLimits[_chainID];
    }

    /**
     * @dev Tells the selector-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _selector method selector for the passed message.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(uint256 _chainID, bytes4 _selector) public view returns (uint256) {
        return selectorGasLimit[_chainID][_selector];
    }

    /**
     * @dev Tells the token-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _selector method selector for the passed message.
     * @param _token address of the native token that is used in the first argument of handleBridgedTokens.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(
        uint256 _chainID,
        bytes4 _selector,
        address _token
    ) public view returns (uint256) {
        return selectorTokenGasLimit[_chainID][_selector][_token];
    }

    /**
     * @dev Tells the gas limit to use for the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _data calldata to be used on the other side of the bridge, when execution a message.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(uint256 _chainID, bytes memory _data) external view returns (uint256) {
        bytes4 selector;
        address token;
        assembly {
            // first 4 bytes of _data contain the selector of the function to be called on the other side of the bridge.
            // mload(add(_data, 4)) loads selector to the 28-31 bytes of the word.
            // shl(28 * 8, x) then used to correct the padding of the selector, putting it to 0-3 bytes of the word.
            selector := shl(224, mload(add(_data, 4)))
            // handleBridgedTokens/handleNativeTokens/... passes bridged token address as the first parameter.
            // it is located in the 4-35 bytes of the calldata.
            // 36 = bytes length padding (32) + selector length (4)
            token := mload(add(_data, 36))
        }
        uint256 gasLimit = selectorTokenGasLimit[_chainID][selector][token];
        if (gasLimit == 0) {
            gasLimit = selectorGasLimit[_chainID][selector];
            if (gasLimit == 0) {
                gasLimit = defaultGasLimits[_chainID];
            }
        }
        return gasLimit;
    }

    /**
     * @dev Sets the default values for different Omnibridge selectors.
     * @param _chainID required network id.
     * @param _gasLimits array with 2 gas limits for the following selectors of the outgoing messages:
     * - handleBridgedTokens
     * - fixFailedMessage
     * Only the owner can call this method.
     */
    function setCommonRequestGasLimits(uint256 _chainID, uint256[] calldata _gasLimits)
        external
        onlyOwner
        validGasLimits(_chainID, 2, _gasLimits)
    {
        selectorGasLimit[_chainID][BasicOmnibridge.handleBridgedTokens.selector] = _gasLimits[0];
        selectorGasLimit[_chainID][FailedMessagesProcessor.fixFailedMessage.selector] = _gasLimits[1];
    }

    /**
     * @dev Sets the request gas limits for some specific token native to the Home side of the bridge.
     * @param _chainID required network id.
     * @param _token address of the native token contract on the Home side.
     * @param _gasLimits array with 1 gas limit for the following selector of the outgoing messages:
     * - handleBridgedTokens
     * Only the owner can call this method.
     */
    function setNativeTokenRequestGasLimits(
        uint256 _chainID,
        address _token,
        uint256[] calldata _gasLimits
    ) external onlyOwner validGasLimits(_chainID, 1, _gasLimits) {
        selectorTokenGasLimit[_chainID][BasicOmnibridge.handleBridgedTokens.selector][_token] = _gasLimits[0];
    }

    /**
     * @dev Internal function for reducing contract bytecode.
     * @param _chainID required network id.
     * @param _length expected length of the gas limits array.
     * @param _gasLimits an array with gas limits.
     */
    function _validGasLimits(
        uint256 _chainID,
        uint256 _length,
        uint256[] calldata _gasLimits
    ) internal view {
        require(_gasLimits.length == _length);
        uint256 maxGasLimit = bridges[_chainID].maxGasPerTx();
        for (uint256 i = 0; i < _length; i++) {
            require(_gasLimits[i] <= maxGasLimit);
        }
    }

    /**
     * @dev Internal function to add new bridges or change existing ones .
     * @param _chainID required network id.
     * @param _bridgeContract address of the bridge contract on the Home side.
     * @param _gasLimit default gas limit
     */
    function _setBridgeContract(
        uint256 _chainID,
        IAMB _bridgeContract,
        uint256 _gasLimit
    ) internal {
        require(_gasLimit <= _bridgeContract.maxGasPerTx());

        bridges[_chainID] = _bridgeContract;
        defaultGasLimits[_chainID] = _gasLimit;
    }
}