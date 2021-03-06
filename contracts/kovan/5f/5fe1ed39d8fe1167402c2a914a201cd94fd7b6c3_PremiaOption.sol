/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// File: @openzeppelin/contracts/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor ()  {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol



pragma solidity >=0.6.0 <0.8.0;








/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_)  {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
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
    function uri(uint256) external view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
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
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

    constructor ()  {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/SafeCast.sol



pragma solidity >=0.6.0 <0.8.0;


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
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/interface/IERC20Extended.sol



pragma solidity ^0.7.0;



interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// File: contracts/interface/IFeeCalculator.sol



pragma solidity ^0.7.0;

interface IFeeCalculator {
    enum FeeType {Write, Exercise, Maker, Taker, FlashLoan}

    function writeFee() external view returns(uint256);
    function exerciseFee() external view returns(uint256);
    function flashLoanFee() external view returns(uint256);

    function referrerFee() external view returns(uint256);
    function referredDiscount() external view returns(uint256);

    function makerFee() external view returns(uint256);
    function takerFee() external view returns(uint256);

    function getFee(address _user, bool _hasReferrer, FeeType _feeType) external view returns(uint256);
    function getFeeAmounts(address _user, bool _hasReferrer, uint256 _amount, FeeType _feeType) external view returns(uint256 _fee, uint256 _feeReferrer);
    function getFeeAmountsWithDiscount(address _user, bool _hasReferrer, uint256 _baseFee) external view returns(uint256 _fee, uint256 _feeReferrer);
}

// File: contracts/interface/IFlashLoanReceiver.sol



pragma solidity ^0.7.0;

interface IFlashLoanReceiver {
    function execute(address _tokenAddress, uint256 _amount, uint256 _amountWithFee) external;
}

// File: contracts/interface/IPremiaReferral.sol



pragma solidity ^0.7.0;

interface IPremiaReferral {
    function referrals(address _referred) external view returns(address _referrer);
    function trySetReferrer(address _referred, address _potentialReferrer) external returns(address);
}

// File: contracts/interface/IPremiaUncutErc20.sol



pragma solidity ^0.7.0;


interface IPremiaUncutErc20 is IERC20 {
    function getTokenPrice(address _token) external view returns(uint256);
    function mint(address _account, uint256 _amount) external;
    function mintReward(address _account, address _token, uint256 _feePaid, uint8 _decimals) external;
}

// File: contracts/uniswapV2/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/uniswapV2/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/PremiaOption.sol



pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;













/// @author Premia
/// @title An option contract
contract PremiaOption is Ownable, ERC1155, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct OptionWriteArgs {
        address token;                  // Token address
        uint256 amount;                 // Amount of tokens to write option for
        uint256 strikePrice;            // Strike price (Must follow strikePriceIncrement of token)
        uint256 expiration;             // Expiration timestamp of the option (Must follow expirationIncrement)
        bool isCall;                    // If true : Call option | If false : Put option
    }

    struct OptionData {
        address token;                  // Token address
        uint256 strikePrice;            // Strike price (Must follow strikePriceIncrement of token)
        uint256 expiration;             // Expiration timestamp of the option (Must follow expirationIncrement)
        bool isCall;                    // If true : Call option | If false : Put option
        uint256 claimsPreExp;           // Amount of options from which the funds have been withdrawn pre expiration
        uint256 claimsPostExp;          // Amount of options from which the funds have been withdrawn post expiration
        uint256 exercised;              // Amount of options which have been exercised
        uint256 supply;                 // Total circulating supply
        uint8 decimals;                 // Token decimals
    }

    // Total write cost = collateral + fee + feeReferrer
    struct QuoteWrite {
        address collateralToken;        // The token to deposit as collateral
        uint256 collateral;             // The amount of collateral to deposit
        uint8 collateralDecimals;       // Decimals of collateral token
        uint256 fee;                    // The amount of collateralToken needed to be paid as protocol fee
        uint256 feeReferrer;            // The amount of collateralToken which will be paid the referrer
    }

    // Total exercise cost = input + fee + feeReferrer
    struct QuoteExercise {
        address inputToken;             // Input token for exercise
        uint256 input;                  // Amount of input token to pay to exercise
        uint8 inputDecimals;            // Decimals of input token
        address outputToken;            // Output token from the exercise
        uint256 output;                 // Amount of output tokens which will be received on exercise
        uint8 outputDecimals;           // Decimals of output token
        uint256 fee;                    // The amount of inputToken needed to be paid as protocol fee
        uint256 feeReferrer;            // The amount of inputToken which will be paid to the referrer
    }

    struct Pool {
        uint256 tokenAmount;            // The amount of tokens in the option pool
        uint256 denominatorAmount;      // The amounts of denominator in the option pool
    }

    IERC20 public denominator;
    uint8 public denominatorDecimals;

    //////////////////////////////////////////////////

    // Address receiving protocol fees (PremiaMaker)
    address public feeRecipient;

    // PremiaReferral contract
    IPremiaReferral public premiaReferral;
    // The uPremia token
    IPremiaUncutErc20 public uPremia;
    // FeeCalculator contract
    IFeeCalculator public feeCalculator;

    //////////////////////////////////////////////////

    // Whitelisted tokens for which options can be written (Each token must also have a non 0 strike price increment to be enabled)
    address[] public tokens;
    // Strike price increment mapping of each token
    mapping (address => uint256) public tokenStrikeIncrement;

    //////////////////////////////////////////////////

    // The option id of next option type which will be created
    uint256 public nextOptionId = 1;

    // Offset to add to Unix timestamp to make it Fri 23:59:59 UTC
    uint256 private constant _baseExpiration = 172799;
    // Expiration increment
    uint256 private constant _expirationIncrement = 1 weeks;
    // Max expiration time from now
    uint256 public maxExpiration = 365 days;

    // Uniswap routers allowed to be used for swap from flashExercise
    address[] public whitelistedUniswapRouters;

    // token => expiration => strikePrice => isCall (1 for call, 0 for put) => optionId
    mapping (address => mapping(uint256 => mapping(uint256 => mapping (bool => uint256)))) public options;

    // optionId => OptionData
    mapping (uint256 => OptionData) public optionData;

    // optionId => Pool
    mapping (uint256 => Pool) public pools;

    // account => optionId => amount of options written
    mapping (address => mapping (uint256 => uint256)) public nbWritten;

    ////////////
    // Events //
    ////////////

    event SetToken(address indexed token, uint256 strikePriceIncrement);
    event OptionIdCreated(uint256 indexed optionId, address indexed token);
    event OptionWritten(address indexed owner, uint256 indexed optionId, address indexed token, uint256 amount);
    event OptionCancelled(address indexed owner, uint256 indexed optionId, address indexed token, uint256 amount);
    event OptionExercised(address indexed user, uint256 indexed optionId, address indexed token, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed optionId, address indexed token, uint256 amount);
    event FeePaid(address indexed user, address indexed token, address indexed referrer, uint256 feeProtocol, uint256 feeReferrer);

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    /// @param _uri URI of ERC1155 metadata
    /// @param _denominator The token used as denominator
    /// @param _uPremia The uPremia token
    /// @param _feeCalculator FeeCalculator contract
    /// @param _premiaReferral PremiaReferral contract
    /// @param _feeRecipient Recipient of protocol fees (PremiaMaker)
    constructor(string memory _uri, IERC20 _denominator, IPremiaUncutErc20 _uPremia, IFeeCalculator _feeCalculator,
        IPremiaReferral _premiaReferral, address _feeRecipient) ERC1155(_uri) {
        denominator = _denominator;
        uPremia = _uPremia;
        feeCalculator = _feeCalculator;
        feeRecipient = _feeRecipient;
        premiaReferral = _premiaReferral;
        denominatorDecimals = IERC20Extended(address(_denominator)).decimals();
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Modifiers //
    ///////////////

    modifier notExpired(uint256 _optionId) {
        require(block.timestamp < optionData[_optionId].expiration, "Expired");
        _;
    }

    modifier expired(uint256 _optionId) {
        require(block.timestamp >= optionData[_optionId].expiration, "Not expired");
        _;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////
    // Admin //
    ///////////

    /// @notice Set new URI for ERC1155 metadata
    /// @param _newUri The new URI
    function setURI(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }

    /// @notice Set new protocol fee recipient
    /// @param _feeRecipient The new protocol fee recipient
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /// @notice Set a new max expiration date for options writing (By default, 1 year from current date)
    /// @param _max The max amount of seconds in the future for which an option expiration can be set
    function setMaxExpiration(uint256 _max) external onlyOwner {
        maxExpiration = _max;
    }

    /// @notice Set a new PremiaReferral contract
    /// @param _premiaReferral The new PremiaReferral Contract
    function setPremiaReferral(IPremiaReferral _premiaReferral) external onlyOwner {
        premiaReferral = _premiaReferral;
    }

    /// @notice Set a new PremiaUncut contract
    /// @param _uPremia The new PremiaUncut Contract
    function setPremiaUncutErc20(IPremiaUncutErc20 _uPremia) external onlyOwner {
        uPremia = _uPremia;
    }

    /// @notice Set a new FeeCalculator contract
    /// @param _feeCalculator The new FeeCalculator Contract
    function setFeeCalculator(IFeeCalculator _feeCalculator) external onlyOwner {
        feeCalculator = _feeCalculator;
    }

    /// @notice Set settings for tokens to support writing of options paired to denominator
    /// @dev A value of 0 means this token is disabled and options cannot be written for it
    /// @param _tokens The list of tokens for which to set strike price increment
    /// @param _strikePriceIncrement The new strike price increment to set for each token
    function setTokens(address[] memory _tokens, uint256[] memory _strikePriceIncrement) external onlyOwner {
        require(_tokens.length == _strikePriceIncrement.length);

        for (uint256 i=0; i < _tokens.length; i++) {
            if (!_isInArray(_tokens[i], tokens)) {
                tokens.push(_tokens[i]);
            }

            require(_tokens[i] != address(denominator), "Cant add denominator");
            tokenStrikeIncrement[_tokens[i]] = _strikePriceIncrement[i];

            emit SetToken(_tokens[i], _strikePriceIncrement[i]);
        }
    }

    /// @notice Set a new list of whitelisted UniswapRouter contracts allowed to be used for flashExercise
    /// @param _addrList The new list of whitelisted routers
    function setWhitelistedUniswapRouters(address[] memory _addrList) external onlyOwner {
        delete whitelistedUniswapRouters;

        for (uint256 i=0; i < _addrList.length; i++) {
            whitelistedUniswapRouters.push(_addrList[i]);
        }
    }

    //////////////////////////////////////////////////

    //////////
    // View //
    //////////

    /// @notice Get the id of an option
    /// @param _token Token for which the option is for
    /// @param _expiration Expiration timestamp of the option
    /// @param _strikePrice Strike price of the option
    /// @param _isCall Whether the option is a call or a put
    /// @return The option id
    function getOptionId(address _token, uint256 _expiration, uint256 _strikePrice, bool _isCall) public view returns(uint256) {
        return options[_token][_expiration][_strikePrice][_isCall];
    }

    /// @notice Get the amount of whitelisted tokens
    /// @return The amount of whitelisted tokens
    function tokensLength() external view returns(uint256) {
        return tokens.length;
    }

    /// @notice Get a quote to write an option
    /// @param _from Address which will write the option
    /// @param _option The option to write
    /// @param _referrer Referrer
    /// @param _decimals The option token decimals
    /// @return The quote
    function getWriteQuote(address _from, OptionWriteArgs memory _option, address _referrer, uint8 _decimals) public view returns(QuoteWrite memory) {
        QuoteWrite memory quote;

        if (_option.isCall) {
            quote.collateralToken = _option.token;
            quote.collateral = _option.amount;
            quote.collateralDecimals = _decimals;
        } else {
            quote.collateralToken = address(denominator);
            quote.collateral = _option.amount.mul(_option.strikePrice).div(10**_decimals);
            quote.collateralDecimals = denominatorDecimals;
        }

        (uint256 fee, uint256 feeReferrer) = feeCalculator.getFeeAmounts(_from, _referrer != address(0), quote.collateral, IFeeCalculator.FeeType.Write);
        quote.fee = fee;
        quote.feeReferrer = feeReferrer;

        return quote;
    }

    /// @notice Get a quote to exercise an option
    /// @param _from Address which will exercise the option
    /// @param _option The option to exercise
    /// @param _referrer Referrer
    /// @param _decimals The option token decimals
    /// @return The quote
    function getExerciseQuote(address _from, OptionData memory _option, uint256 _amount, address _referrer, uint8 _decimals) public view returns(QuoteExercise memory) {
        QuoteExercise memory quote;

        uint256 tokenAmount = _amount;
        uint256 denominatorAmount = _amount.mul(_option.strikePrice).div(10**_decimals);

        if (_option.isCall) {
            quote.inputToken = address(denominator);
            quote.input = denominatorAmount;
            quote.inputDecimals = denominatorDecimals;
            quote.outputToken = _option.token;
            quote.output = tokenAmount;
            quote.outputDecimals = _option.decimals;
        } else {
            quote.inputToken = _option.token;
            quote.input = tokenAmount;
            quote.inputDecimals = _option.decimals;
            quote.outputToken = address(denominator);
            quote.output = denominatorAmount;
            quote.outputDecimals = denominatorDecimals;
        }

        (uint256 fee, uint256 feeReferrer) = feeCalculator.getFeeAmounts(_from, _referrer != address(0), quote.input, IFeeCalculator.FeeType.Exercise);
        quote.fee = fee;
        quote.feeReferrer = feeReferrer;

        return quote;
    }

    //////////////////////////////////////////////////

    //////////
    // Main //
    //////////

    /// @notice Get the id of the option, or create a new id if there is no existing id for it
    /// @param _token Token for which the option is for
    /// @param _expiration Expiration timestamp of the option
    /// @param _strikePrice Strike price of the option
    /// @param _isCall Whether the option is a call or a put
    /// @return The option id
    function getOptionIdOrCreate(address _token, uint256 _expiration, uint256 _strikePrice, bool _isCall) public returns(uint256) {
        uint256 optionId = getOptionId(_token, _expiration, _strikePrice, _isCall);

        if (optionId == 0) {
            _preCheckOptionIdCreate(_token, _strikePrice, _expiration);

            optionId = nextOptionId;
            options[_token][_expiration][_strikePrice][_isCall] = optionId;
            uint8 decimals = IERC20Extended(_token).decimals();
            require(decimals <= 18, "Too many decimals");

            pools[optionId] = Pool({ tokenAmount: 0, denominatorAmount: 0 });
                optionData[optionId] = OptionData({
                token: _token,
                expiration: _expiration,
                strikePrice: _strikePrice,
                isCall: _isCall,
                claimsPreExp: 0,
                claimsPostExp: 0,
                exercised: 0,
                supply: 0,
                decimals: decimals
            });

            emit OptionIdCreated(optionId, _token);

            nextOptionId = nextOptionId.add(1);
        }

        return optionId;
    }

    //////////////////////////////////////////////////

    /// @notice Write an option on behalf of an address with an existing option id (Used by market delayed writing)
    /// @dev Requires approval on option contract + token needed to write the option
    /// @param _from Address on behalf of which the option is written
    /// @param _optionId The id of the option to write
    /// @param _amount Amount of options to write
    /// @param _referrer Referrer
    /// @return The option id
    function writeOptionWithIdFrom(address _from, uint256 _optionId, uint256 _amount, address _referrer) external returns(uint256) {
        require(isApprovedForAll(_from, msg.sender), "Not approved");

        OptionData memory data = optionData[_optionId];
        OptionWriteArgs memory writeArgs = OptionWriteArgs({
        token: data.token,
        amount: _amount,
        strikePrice: data.strikePrice,
        expiration: data.expiration,
        isCall: data.isCall
        });

        return _writeOption(_from, writeArgs, _referrer);
    }

    /// @notice Write an option on behalf of an address
    /// @dev Requires approval on option contract + token needed to write the option
    /// @param _from Address on behalf of which the option is written
    /// @param _option The option to write
    /// @param _referrer Referrer
    /// @return The option id
    function writeOptionFrom(address _from, OptionWriteArgs memory _option, address _referrer) external returns(uint256) {
        require(isApprovedForAll(_from, msg.sender), "Not approved");
        return _writeOption(_from, _option, _referrer);
    }

    /// @notice Write an option
    /// @param _option The option to write
    /// @param _referrer Referrer
    /// @return The option id
    function writeOption(OptionWriteArgs memory _option, address _referrer) public returns(uint256) {
        return _writeOption(msg.sender, _option, _referrer);
    }

    /// @notice Write an option on behalf of an address
    /// @param _from Address on behalf of which the option is written
    /// @param _option The option to write
    /// @param _referrer Referrer
    /// @return The option id
    function _writeOption(address _from, OptionWriteArgs memory _option, address _referrer) internal nonReentrant returns(uint256) {
        require(_option.amount > 0, "Amount <= 0");

        uint256 optionId = getOptionIdOrCreate(_option.token, _option.expiration, _option.strikePrice, _option.isCall);

        // Set referrer or get current if one already exists
        _referrer = _trySetReferrer(_from, _referrer);

        QuoteWrite memory quote = getWriteQuote(_from, _option, _referrer, optionData[optionId].decimals);

        IERC20(quote.collateralToken).safeTransferFrom(_from, address(this), quote.collateral);
        _payFees(_from, IERC20(quote.collateralToken), _referrer, quote.fee, quote.feeReferrer, quote.collateralDecimals);

        if (_option.isCall) {
            pools[optionId].tokenAmount = pools[optionId].tokenAmount.add(quote.collateral);
        } else {
            pools[optionId].denominatorAmount = pools[optionId].denominatorAmount.add(quote.collateral);
        }

        nbWritten[_from][optionId] = nbWritten[_from][optionId].add(_option.amount);

        mint(_from, optionId, _option.amount);

        emit OptionWritten(_from, optionId, _option.token, _option.amount);

        return optionId;
    }

    //////////////////////////////////////////////////

    /// @notice Cancel an option on behalf of an address. This will burn the option ERC1155 and withdraw collateral.
    /// @dev Requires approval of the option contract
    ///      This is only doable by an address which wrote an amount of options >= _amount
    ///      Must be called before expiration
    /// @param _from Address on behalf of which the option is cancelled
    /// @param _optionId The id of the option to cancel
    /// @param _amount Amount to cancel
    function cancelOptionFrom(address _from, uint256 _optionId, uint256 _amount) external {
        require(isApprovedForAll(_from, msg.sender), "Not approved");
        _cancelOption(_from, _optionId, _amount);
    }

    /// @notice Cancel an option. This will burn the option ERC1155 and withdraw collateral.
    /// @dev This is only doable by an address which wrote an amount of options >= _amount
    ///      Must be called before expiration
    /// @param _optionId The id of the option to cancel
    /// @param _amount Amount to cancel
    function cancelOption(uint256 _optionId, uint256 _amount) public {
        _cancelOption(msg.sender, _optionId, _amount);
    }

    /// @notice Cancel an option on behalf of an address. This will burn the option ERC1155 and withdraw collateral.
    /// @dev This is only doable by an address which wrote an amount of options >= _amount
    ///      Must be called before expiration
    /// @param _from Address on behalf of which the option is cancelled
    /// @param _optionId The id of the option to cancel
    /// @param _amount Amount to cancel
    function _cancelOption(address _from, uint256 _optionId, uint256 _amount) internal nonReentrant {
        require(_amount > 0, "Amount <= 0");
        require(nbWritten[_from][_optionId] >= _amount, "Not enough written");

        burn(_from, _optionId, _amount);
        nbWritten[_from][_optionId] = nbWritten[_from][_optionId].sub(_amount);

        if (optionData[_optionId].isCall) {
            pools[_optionId].tokenAmount = pools[_optionId].tokenAmount.sub(_amount);
            IERC20(optionData[_optionId].token).safeTransfer(_from, _amount);
        } else {
            uint256 amount = _amount.mul(optionData[_optionId].strikePrice).div(10**optionData[_optionId].decimals);
            pools[_optionId].denominatorAmount = pools[_optionId].denominatorAmount.sub(amount);
            denominator.safeTransfer(_from, amount);
        }

        emit OptionCancelled(_from, _optionId, optionData[_optionId].token, _amount);
    }

    //////////////////////////////////////////////////

    /// @notice Exercise an option on behalf of an address
    /// @dev Requires approval of the option contract
    /// @param _from Address on behalf of which the option will be exercised
    /// @param _optionId The id of the option to exercise
    /// @param _amount Amount to exercise
    /// @param _referrer Referrer
    function exerciseOptionFrom(address _from, uint256 _optionId, uint256 _amount, address _referrer) external {
        require(isApprovedForAll(_from, msg.sender), "Not approved");
        _exerciseOption(_from, _optionId, _amount, _referrer);
    }

    /// @notice Exercise an option
    /// @param _optionId The id of the option to exercise
    /// @param _amount Amount to exercise
    /// @param _referrer Referrer
    function exerciseOption(uint256 _optionId, uint256 _amount, address _referrer) public {
        _exerciseOption(msg.sender, _optionId, _amount, _referrer);
    }

    /// @notice Exercise an option on behalf of an address
    /// @param _from Address on behalf of which the option will be exercised
    /// @param _optionId The id of the option to exercise
    /// @param _amount Amount to exercise
    /// @param _referrer Referrer
    function _exerciseOption(address _from, uint256 _optionId, uint256 _amount, address _referrer) internal nonReentrant {
        require(_amount > 0, "Amount <= 0");

        OptionData storage data = optionData[_optionId];

        burn(_from, _optionId, _amount);
        data.exercised = uint256(data.exercised).add(_amount);

        // Set referrer or get current if one already exists
        _referrer = _trySetReferrer(_from, _referrer);

        QuoteExercise memory quote = getExerciseQuote(_from, data, _amount, _referrer, data.decimals);
        IERC20(quote.inputToken).safeTransferFrom(_from, address(this), quote.input);
        _payFees(_from, IERC20(quote.inputToken), _referrer, quote.fee, quote.feeReferrer, quote.inputDecimals);

        if (data.isCall) {
            pools[_optionId].tokenAmount = pools[_optionId].tokenAmount.sub(quote.output);
            pools[_optionId].denominatorAmount = pools[_optionId].denominatorAmount.add(quote.input);
        } else {
            pools[_optionId].denominatorAmount = pools[_optionId].denominatorAmount.sub(quote.output);
            pools[_optionId].tokenAmount = pools[_optionId].tokenAmount.add(quote.input);
        }

        IERC20(quote.outputToken).safeTransfer(_from, quote.output);

        emit OptionExercised(_from, _optionId, data.token, _amount);
    }

    //////////////////////////////////////////////////

    /// @notice Withdraw collateral from an option post expiration on behalf of an address.
    ///         (Funds will be send to the address on behalf of which withdrawal is made)
    ///         Funds in the option pool will be distributed pro rata of amount of options written by the address
    ///         Ex : If after expiration date there has been 10 options written and there is 1 eth and 1000 DAI in the pool,
    ///              Withdraw for each option will be worth 0.1 eth and 100 dai
    /// @dev Only callable by addresses which have unclaimed funds for options they wrote
    ///      Requires approval of the option contract
    /// @param _from Address on behalf of which the withdraw call is made (Which will receive the withdrawn funds)
    /// @param _optionId The id of the option to withdraw funds from
    function withdrawFrom(address _from, uint256 _optionId) external {
        require(isApprovedForAll(_from, msg.sender), "Not approved");
        _withdraw(_from, _optionId);
    }

    /// @notice Withdraw collateral from an option post expiration
    ///         Funds in the option pool will be distributed pro rata of amount of options written by the address
    ///         Ex : If after expiration date there has been 10 options written and there is 1 eth and 1000 DAI in the pool,
    ///              Withdraw for each option will be worth 0.1 eth and 100 dai
    /// @dev Only callable by addresses which have unclaimed funds for options they wrote
    /// @param _optionId The id of the option to withdraw funds from
    function withdraw(uint256 _optionId) public {
        _withdraw(msg.sender, _optionId);
    }

    /// @notice Withdraw collateral from an option post expiration on behalf of an address.
    ///         (Funds will be send to the address on behalf of which withdrawal is made)
    ///         Funds in the option pool will be distributed pro rata of amount of options written by the address
    ///         Ex : If after expiration date there has been 10 options written and there is 1 eth and 1000 DAI in the pool,
    ///              Withdraw for each option will be worth 0.1 eth and 100 dai
    /// @dev Only callable by addresses which have unclaimed funds for options they wrote
    /// @param _from Address on behalf of which the withdraw call is made (Which will receive the withdrawn funds)
    /// @param _optionId The id of the option to withdraw funds from
    function _withdraw(address _from, uint256 _optionId) internal nonReentrant expired(_optionId) {
        require(nbWritten[_from][_optionId] > 0, "No option to claim");

        OptionData storage data = optionData[_optionId];

        uint256 nbTotal = uint256(data.supply).add(data.exercised).sub(data.claimsPreExp);

        // Amount of options user still has to claim funds from
        uint256 claimsUser = nbWritten[_from][_optionId];

        //

        uint256 denominatorAmount = pools[_optionId].denominatorAmount.mul(claimsUser).div(nbTotal);
        uint256 tokenAmount = pools[_optionId].tokenAmount.mul(claimsUser).div(nbTotal);

        //

        pools[_optionId].denominatorAmount.sub(denominatorAmount);
        pools[_optionId].tokenAmount.sub(tokenAmount);
        data.claimsPostExp = uint256(data.claimsPostExp).add(claimsUser);
        delete nbWritten[_from][_optionId];

        denominator.safeTransfer(_from, denominatorAmount);
        IERC20(optionData[_optionId].token).safeTransfer(_from, tokenAmount);

        emit Withdraw(_from, _optionId, data.token, claimsUser);
    }

    //////////////////////////////////////////////////

    /// @notice Withdraw collateral from an option pre expiration on behalf of an address.
    ///         (Funds will be send to the address on behalf of which withdrawal is made)
    ///         Only opposite side of the collateral will be allocated when withdrawing pre expiration
    ///         If writer deposited WETH for a WETH/DAI call, he will only receive the strike amount in DAI from a pre-expiration withdrawal,
    ///         while doing a withdrawal post expiration would make him receive pro rata of funds left in the option pool at the expiration,
    ///         (Which might be both WETH and DAI if not all options have been exercised)
    ///
    /// @dev Requires approval of the option contract
    ///      Only callable by addresses which have unclaimed funds for options they wrote
    ///      This also requires options to have been exercised and not claimed
    ///      Ex : If a total of 10 options have been written (2 from Alice and 8 from Bob) and 3 options have been exercise :
    ///           - Alice will be allowed to call withdrawPreExpiration for her 2 options written
    ///           - Bob will only be allowed to call withdrawPreExpiration for 3 options he wrote
    ///           - If Alice call first withdrawPreExpiration for her 2 options,
    ///             there will be only 1 unclaimed exercised options that Bob will be allowed to withdrawPreExpiration
    ///
    /// @param _from Address on behalf of which the withdrawPreExpiration call is made (Which will receive the withdrawn funds)
    /// @param _optionId The id of the option to withdraw funds from
    /// @param _amount The amount of options for which withdrawPreExpiration
    function withdrawPreExpirationFrom(address _from, uint256 _optionId, uint256 _amount) external {
        require(isApprovedForAll(_from, msg.sender), "Not approved");
        _withdrawPreExpiration(_from, _optionId, _amount);
    }

    /// @notice Withdraw collateral from an option pre expiration
    ///         (Funds will be send to the address on behalf of which withdrawal is made)
    ///         Only opposite side of the collateral will be allocated when withdrawing pre expiration
    ///         If writer deposited WETH for a WETH/DAI call, he will only receive the strike amount in DAI from a pre-expiration withdrawal,
    ///         while doing a withdrawal post expiration would make him receive pro rata of funds left in the option pool at the expiration,
    ///         (Which might be both WETH and DAI if not all options have been exercised)
    ///
    /// @dev Only callable by addresses which have unclaimed funds for options they wrote
    ///      This also requires options to have been exercised and not claimed
    ///      Ex : If a total of 10 options have been written (2 from Alice and 8 from Bob) and 3 options have been exercise :
    ///           - Alice will be allowed to call withdrawPreExpiration for her 2 options written
    ///           - Bob will only be allowed to call withdrawPreExpiration for 3 options he wrote
    ///           - If Alice call first withdrawPreExpiration for her 2 options,
    ///             there will be only 1 unclaimed exercised options that Bob will be allowed to withdrawPreExpiration
    ///
    /// @param _optionId The id of the option to exercise
    /// @param _amount The amount of options for which withdrawPreExpiration
    function withdrawPreExpiration(uint256 _optionId, uint256 _amount) public {
        _withdrawPreExpiration(msg.sender, _optionId, _amount);
    }

    /// @notice Withdraw collateral from an option pre expiration on behalf of an address.
    ///         (Funds will be send to the address on behalf of which withdrawal is made)
    ///         Only opposite side of the collateral will be allocated when withdrawing pre expiration
    ///         If writer deposited WETH for a WETH/DAI call, he will only receive the strike amount in DAI from a pre-expiration withdrawal,
    ///         while doing a withdrawal post expiration would make him receive pro rata of funds left in the option pool at the expiration,
    ///         (Which might be both WETH and DAI if not all options have been exercised)
    ///
    /// @dev Only callable by addresses which have unclaimed funds for options they wrote
    ///      This also requires options to have been exercised and not claimed
    ///      Ex : If a total of 10 options have been written (2 from Alice and 8 from Bob) and 3 options have been exercise :
    ///           - Alice will be allowed to call withdrawPreExpiration for her 2 options written
    ///           - Bob will only be allowed to call withdrawPreExpiration for 3 options he wrote
    ///           - If Alice call first withdrawPreExpiration for her 2 options,
    ///             there will be only 1 unclaimed exercised options that Bob will be allowed to withdrawPreExpiration
    ///
    /// @param _from Address on behalf of which the withdrawPreExpiration call is made (Which will receive the withdrawn funds)
    /// @param _optionId The id of the option to withdraw funds from
    /// @param _amount The amount of options for which withdrawPreExpiration
    function _withdrawPreExpiration(address _from, uint256 _optionId, uint256 _amount) internal nonReentrant notExpired(_optionId) {
        require(_amount > 0, "Amount <= 0");

        // Amount of options user still has to claim funds from
        uint256 claimsUser = nbWritten[_from][_optionId];
        require(claimsUser >= _amount, "Not enough claims");

        OptionData storage data = optionData[_optionId];

        uint256 nbClaimable = uint256(data.exercised).sub(data.claimsPreExp);
        require(nbClaimable >= _amount, "Not enough claimable");

        //

        nbWritten[_from][_optionId] = nbWritten[_from][_optionId].sub(_amount);
        data.claimsPreExp = uint256(data.claimsPreExp).add(_amount);

        if (data.isCall) {
            uint256 amount = _amount.mul(data.strikePrice).div(10**data.decimals);
            pools[_optionId].denominatorAmount = pools[_optionId].denominatorAmount.sub(amount);
            denominator.safeTransfer(_from, amount);
        } else {
            pools[_optionId].tokenAmount = pools[_optionId].tokenAmount.sub(_amount);
            IERC20(data.token).safeTransfer(_from, _amount);
        }
    }

    //////////////////////////////////////////////////

    /// @notice Flash exercise an option on behalf of an address
    ///         This is usable on options in the money, in order to use a portion of the option collateral
    ///         to swap a portion of it to the token required to exercise the option and pay protocol fees,
    ///         and send the profit to the address exercising.
    ///         This allows any option in the money to be exercised without the need of owning the token needed to exercise
    /// @dev Requires approval of the option contract
    /// @param _from Address on behalf of which the flash exercise is made (Which will receive the profit)
    /// @param _optionId The id of the option to flash exercise
    /// @param _amount Amount of option to flash exercise
    /// @param _referrer Referrer
    /// @param _router The UniswapRouter used to perform the swap (Needs to be a whitelisted router)
    /// @param _amountInMax Max amount of collateral token to use for the swap, for the tx to not be reverted
    /// @param _path Path used for the routing of the swap
    function flashExerciseOptionFrom(address _from, uint256 _optionId, uint256 _amount, address _referrer, IUniswapV2Router02 _router, uint256 _amountInMax, address[] memory _path) external {
        require(isApprovedForAll(_from, msg.sender), "Not approved");
        _flashExerciseOption(_from, _optionId, _amount, _referrer, _router, _amountInMax, _path);
    }

    /// @notice Flash exercise an option
    ///         This is usable on options in the money, in order to use a portion of the option collateral
    ///         to swap a portion of it to the token required to exercise the option and pay protocol fees,
    ///         and send the profit to the address exercising.
    ///         This allows any option in the money to be exercised without the need of owning the token needed to exercise
    /// @param _optionId The id of the option to flash exercise
    /// @param _amount Amount of option to flash exercise
    /// @param _referrer Referrer
    /// @param _router The UniswapRouter used to perform the swap (Needs to be a whitelisted router)
    /// @param _amountInMax Max amount of collateral token to use for the swap, for the tx to not be reverted
    /// @param _path Path used for the routing of the swap
    function flashExerciseOption(uint256 _optionId, uint256 _amount, address _referrer, IUniswapV2Router02 _router, uint256 _amountInMax, address[] memory _path) external {
        _flashExerciseOption(msg.sender, _optionId, _amount, _referrer, _router, _amountInMax, _path);
    }

    /// @notice Flash exercise an option on behalf of an address
    ///         This is usable on options in the money, in order to use a portion of the option collateral
    ///         to swap a portion of it to the token required to exercise the option and pay protocol fees,
    ///         and send the profit to the address exercising.
    ///         This allows any option in the money to be exercised without the need of owning the token needed to exercise
    /// @dev Requires approval of the option contract
    /// @param _from Address on behalf of which the flash exercise is made (Which will receive the profit)
    /// @param _optionId The id of the option to flash exercise
    /// @param _amount Amount of option to flash exercise
    /// @param _referrer Referrer
    /// @param _router The UniswapRouter used to perform the swap (Needs to be a whitelisted router)
    /// @param _amountInMax Max amount of collateral token to use for the swap, for the tx to not be reverted
    /// @param _path Path used for the routing of the swap
    function _flashExerciseOption(address _from, uint256 _optionId, uint256 _amount, address _referrer, IUniswapV2Router02 _router, uint256 _amountInMax, address[] memory _path) internal nonReentrant {
        require(_amount > 0, "Amount <= 0");

        burn(_from, _optionId, _amount);
        optionData[_optionId].exercised = uint256(optionData[_optionId].exercised).add(_amount);

        // Set referrer or get current if one already exists
        _referrer = _trySetReferrer(_from, _referrer);

        QuoteExercise memory quote = getExerciseQuote(_from, optionData[_optionId], _amount, _referrer, optionData[_optionId].decimals);

        IERC20 tokenErc20 = IERC20(optionData[_optionId].token);

        uint256 tokenAmountRequired = tokenErc20.balanceOf(address(this));
        uint256 denominatorAmountRequired = denominator.balanceOf(address(this));

        if (optionData[_optionId].isCall) {
            pools[_optionId].tokenAmount = pools[_optionId].tokenAmount.sub(quote.output);
            pools[_optionId].denominatorAmount = pools[_optionId].denominatorAmount.add(quote.input);
        } else {
            pools[_optionId].denominatorAmount = pools[_optionId].denominatorAmount.sub(quote.output);
            pools[_optionId].tokenAmount = pools[_optionId].tokenAmount.add(quote.input);
        }

        //

        if (quote.output < _amountInMax) {
            _amountInMax = quote.output;
        }

        // Swap enough denominator to tokenErc20 to pay fee + strike price
        uint256 tokenAmountUsed = _swap(_router, quote.outputToken, quote.inputToken, quote.input.add(quote.fee).add(quote.feeReferrer), _amountInMax, _path)[0];

        // Pay fees
        _payFees(address(this), IERC20(quote.inputToken), _referrer, quote.fee, quote.feeReferrer, quote.inputDecimals);

        uint256 profit = quote.output.sub(tokenAmountUsed);

        // Send profit to sender
        IERC20(quote.outputToken).safeTransfer(_from, profit);

        //

        if (optionData[_optionId].isCall) {
            denominatorAmountRequired = denominatorAmountRequired.add(quote.input);
            tokenAmountRequired = tokenAmountRequired.sub(quote.output);
        } else {
            denominatorAmountRequired = denominatorAmountRequired.sub(quote.output);
            tokenAmountRequired = tokenAmountRequired.add(quote.input);
        }

        require(denominator.balanceOf(address(this)) >= denominatorAmountRequired, "Wrong denom bal");
        require(tokenErc20.balanceOf(address(this)) >= tokenAmountRequired, "Wrong token bal");

        emit OptionExercised(_from, _optionId, optionData[_optionId].token, _amount);
    }

    //////////////////////////////////////////////////

    /// @notice Flash loan collaterals sitting in this contract
    ///         Loaned amount + fee must be repaid by the end of the transaction for the transaction to not be reverted
    /// @param _tokenAddress Token to flashLoan
    /// @param _amount Amount to flashLoan
    /// @param _receiver Receiver of the flashLoan
    function flashLoan(address _tokenAddress, uint256 _amount, IFlashLoanReceiver _receiver) public nonReentrant {
        IERC20 _token = IERC20(_tokenAddress);
        uint256 startBalance = _token.balanceOf(address(this));
        _token.safeTransfer(address(_receiver), _amount);

        (uint256 fee,) = feeCalculator.getFeeAmounts(msg.sender, false, _amount, IFeeCalculator.FeeType.FlashLoan);

        _receiver.execute(_tokenAddress, _amount, _amount.add(fee));

        uint256 endBalance = _token.balanceOf(address(this));

        uint256 endBalanceRequired = startBalance.add(fee);

        require(endBalance >= endBalanceRequired, "Failed to pay back");
        _token.safeTransfer(feeRecipient, endBalance.sub(startBalance));

        endBalance = _token.balanceOf(address(this));
        require(endBalance >= startBalance, "Failed to pay back");
    }

    //////////////////////////////////////////////////

    //////////////
    // Internal //
    //////////////

    /// @notice Mint ERC1155 representing the option
    /// @dev Requires option to not be expired
    /// @param _account Address for which ERC1155 is minted
    /// @param _amount Amount minted
    function mint(address _account, uint256 _id, uint256 _amount) internal notExpired(_id) {
        OptionData storage data = optionData[_id];

        _mint(_account, _id, _amount, "");
        data.supply = uint256(data.supply).add(_amount);
    }

    /// @notice Burn ERC1155 representing the option
    /// @param _account Address from which ERC1155 is burnt
    /// @param _amount Amount burnt
    function burn(address _account, uint256 _id, uint256 _amount) internal notExpired(_id) {
        OptionData storage data = optionData[_id];

        data.supply = uint256(data.supply).sub(_amount);
        _burn(_account, _id, _amount);
    }

    /// @notice Utility function to check if a value is inside an array
    /// @param _value The value to look for
    /// @param _array The array to check
    /// @return Whether the value is in the array or not
    function _isInArray(address _value, address[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }

        return false;
    }

    /// @notice Pay protocol fees
    /// @param _from Address paying protocol fees
    /// @param _token The token in which protocol fees are paid
    /// @param _referrer The referrer of _from
    /// @param _fee Protocol fee to pay to feeRecipient
    /// @param _feeReferrer Fee to pay to referrer
    /// @param _decimals Token decimals
    function _payFees(address _from, IERC20 _token, address _referrer, uint256 _fee, uint256 _feeReferrer, uint8 _decimals) internal {
        if (_fee > 0) {
            // For flash exercise
            if (_from == address(this)) {
                _token.safeTransfer(feeRecipient, _fee);
            } else {
                _token.safeTransferFrom(_from, feeRecipient, _fee);
            }

        }

        if (_feeReferrer > 0) {
            // For flash exercise
            if (_from == address(this)) {
                _token.safeTransfer(_referrer, _feeReferrer);
            } else {
                _token.safeTransferFrom(_from, _referrer, _feeReferrer);
            }
        }

        // If uPremia rewards are enabled
        if (address(uPremia) != address(0)) {
            uint256 totalFee = _fee.add(_feeReferrer);
            if (totalFee > 0) {
                uPremia.mintReward(_from, address(_token), totalFee, _decimals);
            }
        }

        emit FeePaid(_from, address(_token), _referrer, _fee, _feeReferrer);
    }

    /// @notice Try to set given referrer, returns current referrer if one already exists
    /// @param _user Address for which we try to set a referrer
    /// @param _referrer Potential referrer
    /// @return Actual referrer (Potential referrer, or actual referrer if one already exists)
    function _trySetReferrer(address _user, address _referrer) internal returns(address) {
        if (address(premiaReferral) != address(0)) {
            _referrer = premiaReferral.trySetReferrer(_user, _referrer);
        } else {
            _referrer = address(0);
        }

        return _referrer;
    }

    /// @notice Token swap (Used for flashExercise)
    /// @param _router The UniswapRouter contract to use to perform the swap (Must be whitelisted)
    /// @param _from Input token for the swap
    /// @param _to Output token of the swap
    /// @param _amount Amount of output tokens we want
    /// @param _amountInMax Max amount of input token to spend for the tx to not revert
    /// @param _path Path used for the routing of the swap
    /// @return Swap amounts
    function _swap(IUniswapV2Router02 _router, address _from, address _to, uint256 _amount, uint256 _amountInMax, address[] memory _path) internal returns (uint256[] memory) {
        require(_isInArray(address(_router), whitelistedUniswapRouters), "Router not whitelisted");

        IERC20(_from).approve(address(_router), _amountInMax);

        uint256[] memory amounts = _router.swapTokensForExactTokens(
            _amount,
            _amountInMax,
            _path,
            address(this),
            block.timestamp.add(60)
        );
        _to = _to;

        IERC20(_from).approve(address(_router), 0);

        return amounts;
    }

    /// @notice Check if option settings are valid (Reverts if not valid)
    /// @param _token Token for which option this
    /// @param _strikePrice Strike price of the option
    /// @param _expiration timestamp of the option
    function _preCheckOptionIdCreate(address _token, uint256 _strikePrice, uint256 _expiration) internal view {
        require(tokenStrikeIncrement[_token] != 0, "Token not supported");
        require(_strikePrice > 0, "Strike <= 0");
        require(_strikePrice % tokenStrikeIncrement[_token] == 0, "Wrong strike incr");
        require(_expiration > block.timestamp, "Exp passed");
        require(_expiration.sub(block.timestamp) <= maxExpiration, "Exp > 1 yr");
        require(_expiration % _expirationIncrement == _baseExpiration, "Wrong exp incr");
    }
}