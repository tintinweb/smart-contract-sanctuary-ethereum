/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: contracts/AwooModels.sol



pragma solidity 0.8.12;

struct AccrualDetails{
    address ContractAddress;
    uint256[] TokenIds;
    uint256[] Accruals;
    uint256 TotalAccrued;
}

struct ClaimDetails{
    address ContractAddress;
    uint32[] TokenIds;
}

struct SupportedContractDetails{
    address ContractAddress;
    uint256 BaseRate;
    bool Active;
}
// File: contracts/IAwooClaimingV2.sol



pragma solidity 0.8.12;


interface IAwooClaimingV2{
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate) external;
    function claim(address holder, ClaimDetails[] calldata requestedClaims) external;
}
// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: contracts/IAwooToken.sol



pragma solidity 0.8.12;


interface IAwooToken is IERC20 {
    function increaseVirtualBalance(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
    function balanceOfVirtual(address account) external view returns(uint256);
    function spendVirtualAwoo(bytes32 hash, bytes memory sig, string calldata nonce, address account, uint256 amount) external;
}
// File: @openzeppelin/[email protected]/utils/Strings.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/OwnerAdminGuard.sol



pragma solidity 0.8.12;


contract OwnerAdminGuard is Ownable {
    address[2] private _admins;
    bool private _adminsSet;

    /// @notice Allows the owner to specify two addresses allowed to administer this contract
    /// @param admins A 2 item array of addresses
    function setAdmins(address[2] calldata admins) public {
        require(admins[0] != address(0) && admins[1] != address(0), "Invalid admin address");
        _admins = admins;
        _adminsSet = true;
    }

    function _isOwnerOrAdmin(address addr) internal virtual view returns(bool){
        return addr == owner() || (
            _adminsSet && (
                addr == _admins[0] || addr == _admins[1]
            )
        );
    }

    modifier onlyOwnerOrAdmin() {
        require(_isOwnerOrAdmin(msg.sender), "Not an owner or admin");
        _;
    }
}
// File: contracts/AuthorizedCallerGuard.sol



pragma solidity 0.8.12;


contract AuthorizedCallerGuard is OwnerAdminGuard {

    /// @dev Keeps track of which contracts are explicitly allowed to interact with certain super contract functionality
    mapping(address => bool) public authorizedContracts;

    event AuthorizedContractAdded(address contractAddress, address addedBy);
    event AuthorizedContractRemoved(address contractAddress, address removedBy);

    /// @notice Allows the owner or an admin to authorize another contract to override token accruals on an individual token level
    /// @param contractAddress The authorized contract address
    function addAuthorizedContract(address contractAddress) public onlyOwnerOrAdmin {
        require(_isContract(contractAddress), "Invalid contractAddress");
        authorizedContracts[contractAddress] = true;
        emit AuthorizedContractAdded(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to remove an authorized contract
    /// @param contractAddress The contract address which should have its authorization revoked
    function removeAuthorizedContract(address contractAddress) public onlyOwnerOrAdmin {
        authorizedContracts[contractAddress] = false;
        emit AuthorizedContractRemoved(contractAddress, _msgSender());
    }

    /// @dev Derived from @openzeppelin/contracts/utils/Address.sol
    function _isContract(address account) internal virtual view returns (bool) {
        if(account == address(0)) return false;
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _isAuthorizedContract(address addr) internal virtual view returns(bool){
        return authorizedContracts[addr];
    }

    modifier onlyAuthorizedCaller() {
        require(_isOwnerOrAdmin(_msgSender()) || _isAuthorizedContract(_msgSender()), "Sender is not authorized");
        _;
    }

    modifier onlyAuthorizedContract() {
        require(_isAuthorizedContract(_msgSender()), "Sender is not authorized");
        _;
    }

}
// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: contracts/IAwooMintableCollection.sol



pragma solidity 0.8.12;


interface IAwooMintableCollection is IERC1155 {
    struct TokenDetail { bool SoftLimit; bool Active; }
    struct TokenCount { uint256 TokenId; uint256 Count; }

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function mint(address to, uint256 id, uint256 qty) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory quantities) external;
    function burn(address from, uint256 id, uint256 qty) external;
    function tokensOfOwner(address owner) external view returns (TokenCount[] memory);
    function totalMinted(uint256 id) external view returns(uint256);
    function totalSupply(uint256 id) external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
    function addToken(TokenDetail calldata tokenDetail, string memory tokenUri) external returns(uint256);
    function setTokenUri(uint256 id, string memory tokenUri) external;
    function setTokenActive(uint256 id, bool active) external;
    function setBaseUri(string memory baseUri) external;
}
// File: @openzeppelin/[email protected]/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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

// File: @openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
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

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// File: contracts/AwooCollection.sol



pragma solidity 0.8.12;





contract AwooCollection is IAwooMintableCollection, ERC1155Supply, AuthorizedCallerGuard {
    using Strings for uint256;

    string public constant name = "Awoo Items";
    string public constant symbol = "AWOOI";

    uint16 public currentTokenId;
    bool public isActive;

    /// @notice Maps the tokenId of a specific mintable item to the details that define that item
    mapping(uint256 => TokenDetail) public tokenDetails;

    /// @notice Keeps track of the number of tokens that were burned to support "Soft" limits
    /// @dev Soft limits are the number of tokens available at any given time, so if 1 is burned, another can be minted
    mapping(uint256 => uint256) public tokenBurnCounts;

    /// @dev Allows us to have token-specific metadata uris that will override the baseUri
    mapping(uint256 => string) private _tokenUris;

    event TokenUriUpdated(uint256 indexed id, string newUri, address updatedBy);
    
    constructor(address awooStoreAddress, string memory baseUri) ERC1155(baseUri){
        // Allow the Awoo Store contract to interact with this contract to faciliate minting and burning
        addAuthorizedContract(awooStoreAddress);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IAwooMintableCollection) returns (bool) {
        return super.supportsInterface(interfaceId) ||
            interfaceId == type(IAwooMintableCollection).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == ERC1155Supply.totalSupply.selector ||
            interfaceId == ERC1155Supply.exists.selector;
    }

    /// @notice Allows authorized contracts to mints tokens to the specified recipient
    /// @param to The recipient address
    /// @param id The Id of the specific token to mint
    /// @param qty The number of specified tokens that should be minted
    function mint(address to, uint256 id, uint256 qty
    ) external whenActive onlyAuthorizedContract {
        _mint(to, id, qty, "");
    }

    /// @notice Allows authorized contracts to mint multiple different tokens to the specified recipient
    /// @param to The recipient address
    /// @param ids The Ids of the specific tokens to mint
    /// @param quantities The number of each of the specified tokens that should be minted
    function mintBatch(address to, uint256[] memory ids, uint256[] memory quantities
    ) external whenActive onlyAuthorizedContract {
        _mintBatch(to, ids, quantities, "");
    }

    /// @notice Burns the specified number of tokens.
    /// @notice Only the holder or an approved operator is authorized to burn
    /// @notice Operator approvals must have been explicitly allowed by the token holder
    /// @param from The account from which the specified tokens will be burned
    /// @param id The Id of the tokens that will be burned
    /// @param qty The number of specified tokens that will be burned
    function burn(address from, uint256 id, uint256 qty) external {
        require(exists(id), "Query for non-existent id");
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "Not owner or approved");
        _burn(from, id, qty);
    }

    /// @notice Burns the specified number of each of the specified tokens.
    /// @notice Only the holder or an approved operator is authorized to burn
    /// @notice Operator approvals must have been explicitly allowed by the token holder
    /// @param from The account from which the specified tokens will be burned
    /// @param ids The Ids of the tokens that will be burned
    /// @param quantities The number of each of the specified tokens that will be burned
    function burnBatch(address from, uint256[] memory ids, uint256[] memory quantities) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "Not owner or approved");
        
        for(uint256 i; i < ids.length; i++){
            require(exists(ids[i]), "Query for non-existent id");
        }
        
        _burnBatch(from, ids, quantities);
    }

    /// @notice Returns the metadata uri for the specified token
    /// @dev By default, token-specific uris are given preference
    /// @param id The id of the token for which the uri should be returned
    /// @return A uri string
    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "Query for non-existent id");
        return bytes(_tokenUris[id]).length > 0 ? _tokenUris[id] : string.concat(ERC1155.uri(id), id.toString(), ".json");
    }

    /// @notice Returns the number of each token held by the specified owner address
    /// @param owner The address of the token owner/holder
    /// @return An array of Tuple(uint256,uint256) indicating the number of tokens held
    function tokensOfOwner(address owner) external view returns (TokenCount[] memory) {
        TokenCount[] memory ownerTokenCounts = new TokenCount[](currentTokenId);
        
        for(uint256 i = 1; i <= currentTokenId; i++){
            uint256 count = balanceOf(owner, i);
            ownerTokenCounts[i-1] = TokenCount(i, count);
        }
        return ownerTokenCounts;
    }

    /// @notice Returns the total number of tokens minted for the specified token id
    /// @dev For tokens that have a soft limit, the number of burned tokens is included
    /// so the result is based on the total number of tokens minted, regardless of whether
    /// or not they were subsequently burned
    /// @param id The id of the token to query
    /// @return A uint256 value indicating the total number of tokens minted and burned for the specified token id 
    function totalMinted(uint256 id) isValidTokenId(id) external view returns(uint256) {
        TokenDetail memory tokenDetail = tokenDetails[id];
        
        if(tokenDetail.SoftLimit){
            return ERC1155Supply.totalSupply(id);
        }
        else {
            return (ERC1155Supply.totalSupply(id) + tokenBurnCounts[id]);
        }        
    }

    /// @notice Returns the current number of tokens that were minted and not burned
    /// @param id The id of the token to query
    /// @return A uint256 value indicating the number of tokens which have not been burned
    function totalSupply(uint256 id) public view virtual override(ERC1155Supply,IAwooMintableCollection) returns (uint256) {
        return ERC1155Supply.totalSupply(id);
    }

    /// @notice Determines whether or not the specified token id is valid and at least 1 has been minted
    /// @param id The id of the token to validate
    /// @return A boolean value indicating the existence of the specified token id
    function exists(uint256 id) public view virtual override(ERC1155Supply,IAwooMintableCollection) returns (bool) {
        return ERC1155Supply.exists(id);
    }

    /// @notice Allows authorized individuals or contracts to add new tokens that can be minted    
    /// @param tokenDetail An object describing the token being added
    /// @param tokenUri The specific uri to use for the token being added
    /// @return A uint256 value representing the id of the token
    function addToken(TokenDetail calldata tokenDetail, string memory tokenUri) external isAuthorized returns(uint256){
        currentTokenId++;
        if(bytes(tokenUri).length > 0) {
            _tokenUris[currentTokenId] = tokenUri;
        }
        tokenDetails[currentTokenId] = tokenDetail;
        return currentTokenId;
    }

    /// @notice Allows authorized individuals or contracts to set the base metadata uri
    /// @dev It is assumed that the baseUri value will end with /
    /// @param baseUri The uri to use as the base for all tokens that don't have a token-specific uri
    function setBaseUri(string memory baseUri) external isAuthorized {
        _setURI(baseUri);
    }

    /// @notice Allows authorized individuals or contracts to set the base metadata uri on a per token level
    /// @param id The id of the token
    /// @param tokenUri The uri to use for the specified token id
    function setTokenUri(uint256 id, string memory tokenUri) external isAuthorized isValidTokenId(id) {        
        _tokenUris[id] = tokenUri;
        emit TokenUriUpdated(id, tokenUri, _msgSender());
    }

    /// @notice Allows authorized individuals or contracts to activate/deactivate minting of the specified token id
    /// @param id The id of the token
    /// @param active A boolean value indicating whether or not minting is allowed for this token
    function setTokenActive(uint256 id, bool active) external isAuthorized isValidTokenId(id) {
        tokenDetails[id].Active = active;
    }

    /// @notice Allows authorized individuals to activate/deactivate minting of all tokens
    /// @param active A boolean value indicating whether or not minting is allowed
    function setActive(bool active) external onlyOwnerOrAdmin {
        isActive = active;
    }

    function rescueEth() external onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

    /// @dev Hook to allows us to count the burned tokens even if they're just transferred to the zero address
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids,
        uint256[] memory amounts, bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                tokenBurnCounts[ids[i]] += amounts[i];
            }
        }
    }

    modifier whenActive(){
        require(isActive, "Minting inactive");
        _;
    }

    modifier isValidTokenId(uint256 id) {
        require(id <= currentTokenId, "Invalid tokenId");
        _;
    }

    modifier isValidTokenIds(uint256[] memory ids){
        for(uint256 i = 0; i < ids.length; i++){
            require(ids[i] <= currentTokenId, "Invalid tokenId");
        }
        _;
    }

    modifier isAuthorized() {
        require(_isAuthorizedContract(_msgSender()) || _isOwnerOrAdmin(_msgSender()), "Unauthorized");
        _;
    }

}
// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/AwooStoreV2.sol



pragma solidity 0.8.12;











contract AwooStoreV2 is OwnerAdminGuard {
    struct AwooSpendApproval {
        bytes32 Hash;
        bytes Sig;
        string Nonce;
    }

    enum PaymentType {
        AWOO,
        ETHER,
        AWOO_AND_ETHER,
        FREE
    }

    struct UpgradeDetail {
        uint8 ApplicableCollectionId;
        bool UpgradeItem;
        bool Stackable;
        uint256 UpgradeBaseAccrualRate;
    }

    struct ItemDetail {
        uint16 TotalAvailable;
        uint16 PerAddressLimit;
        uint16 PerTransactionLimit;
        PaymentType PmtType;
        bool Burnable;
        bool NonMintable;
        bool Active;
        IAwooMintableCollection.TokenDetail TokenDetails;
        UpgradeDetail UpgradeDetails;
        string MetadataUri;
        uint256 TokenId;
        uint256 EtherPrice;
        uint256 AWOOPrice;
    }

    address payable public withdrawAddress;
    IAwooToken public awooContract;
    IAwooClaimingV2 public awooClaimingContract;
    IAwooMintableCollection public awooMintableCollectionContract;

    bool public storeActive;

    /// @dev Helps us track the supported ERC721Enumerable contracts so we can refer to them by their
    /// "id" to save a bit of gas
    uint8 public collectionCount;

    /// @dev Helps us track the available items so we can refer to them by their "id" to save a bit of gas
    uint16 public itemCount;

    /// @notice Maps the supported ERC721Enumerable contracts to their Ids
    mapping(uint8 => address) public collectionIdAddressMap;

    /// @notice Maps the available items to their Ids
    mapping(uint16 => ItemDetail) public itemIdDetailMap;

    /// @notice Maps the number of purchased (not minted) items
    mapping(uint16 => uint256) public purchasedItemCount;

    /// @notice Maps item ownership counts
    // owner => (itemId, count).  This is only relevant for items that weren't minted
    mapping(address => mapping(uint16 => uint256))
        public ownedItemCountsByOwner;

    /// @notice Keeps track of how many of each token has been minted by a particular address
    // owner => (itemId, count)
    mapping(address => mapping(uint16 => uint256))
        public mintedItemCountsByAddress;

    /// @notice Keeps track of "upgrade" item applications
    // itemId => (collectionId, applicationTokenIds)
    mapping(uint16 => mapping(uint8 => uint256[])) public itemApplications;

    /// @notice Keeps track of "upgrade" items by the collection that they were applied to
    // collectionId => (tokenId, (itemId => count))
    mapping(uint8 => mapping(uint32 => mapping(uint16 => uint256)))
        public tokenAppliedItemCountsByCollection;

    /// @notice A method that tells us that an "upgrade" item was applied so we can do some cool stuff
    event UpgradeItemApplied(
        uint16 itemId,
        address applicationCollectionAddress,
        uint256 appliedToTokenId
    );
    // ;)
    event NonMintableItemUsed(uint16 itemId, address usedBy, uint256 qty);
    event ItemPurchased(uint16 itemId, address purchasedBy, uint256 qty);

    constructor(
        address payable withdrawAddr,
        IAwooToken awooTokenContract,
        IAwooClaimingV2 claimingContract
    ) {
        require(withdrawAddr != address(0), "Invalid address");

        withdrawAddress = withdrawAddr;
        awooContract = awooTokenContract;
        awooClaimingContract = claimingContract;
    }

    /// @notice Allows the specified item to be minted with AWOO
    /// @param itemId The id of the item to mint
    /// @param qty The number of items to mint
    /// @param approval An object containing the signed message details authorizing us to spend the holders AWOO
    /// @param requestedClaims An optional array of ClaimDetails so we can automagically claim the necessary
    /// amount of AWOO, as specified through NFC
    function mintWithAwoo(
        uint16 itemId,
        uint256 qty,
        AwooSpendApproval calldata approval,
        ClaimDetails[] calldata requestedClaims
    ) public whenStoreActive nonZeroQuantity(qty) {
        ItemDetail memory item = _validateItem(itemId, PaymentType.AWOO);
        require(!item.NonMintable, "Specified item is not mintable");

        _validateRequestedQuantity(itemId, item, qty);
        _ensureAvailablity(item, itemId, qty);

        _claimAwoo(requestedClaims);
        awooContract.spendVirtualAwoo(
            approval.Hash,
            approval.Sig,
            approval.Nonce,
            _msgSender(),
            qty * item.AWOOPrice
        );
        awooMintableCollectionContract.mint(_msgSender(), item.TokenId, qty);
        mintedItemCountsByAddress[_msgSender()][itemId] += qty;
    }

    /// @notice Allows the specified item to be minted with Ether
    /// @param itemId The id of the item to mint
    /// @param qty The number of items to mint
    function mintWithEth(uint16 itemId, uint256 qty)
        public
        payable
        whenStoreActive
        nonZeroQuantity(qty)
    {
        ItemDetail memory item = _validateItem(itemId, PaymentType.ETHER);
        require(!item.NonMintable, "Specified item is not mintable");

        _validateRequestedQuantity(itemId, item, qty);
        _ensureAvailablity(item, itemId, qty);
        _validateEtherValue(item, qty);

        awooMintableCollectionContract.mint(_msgSender(), item.TokenId, qty);
        mintedItemCountsByAddress[_msgSender()][itemId] += qty;
    }

    /// @notice Allows the specified item to be minted with both AWOO and Ether, if the item supports that
    /// @param itemId The id of the item to mint
    /// @param qty The number of items to mint
    /// @param approval An object containing the signed message details authorizing us to spend the holders AWOO
    /// @param requestedClaims An optional array of ClaimDetails so we can automagically claim the necessary
    /// amount of AWOO, as specified through NFC
    function mintWithEthAndAwoo(
        uint16 itemId,
        uint256 qty,
        AwooSpendApproval calldata approval,
        ClaimDetails[] calldata requestedClaims
    ) public payable whenStoreActive nonZeroQuantity(qty) {
        ItemDetail memory item = _validateItem(
            itemId,
            PaymentType.AWOO_AND_ETHER
        );
        require(!item.NonMintable, "Specified item is not mintable");
        _validateRequestedQuantity(itemId, item, qty);
        _ensureAvailablity(item, itemId, qty);
        _validateEtherValue(item, qty);

        _claimAwoo(requestedClaims);
        awooContract.spendVirtualAwoo(
            approval.Hash,
            approval.Sig,
            approval.Nonce,
            _msgSender(),
            qty * item.AWOOPrice
        );

        awooMintableCollectionContract.mint(_msgSender(), item.TokenId, qty);
        mintedItemCountsByAddress[_msgSender()][itemId] += qty;
    }

    /// @notice Allows the specified item to be purchased with AWOO
    /// @param itemId The id of the item to purchase
    /// @param qty The number of items to purchase
    /// @param approval An object containing the signed message details authorizing us to spend the holders AWOO
    /// @param requestedClaims An optional array of ClaimDetails so we can automagically claim the necessary
    /// amount of AWOO, as specified through NFC
    function purchaseWithAwoo(
        uint16 itemId,
        uint256 qty,
        AwooSpendApproval calldata approval,
        ClaimDetails[] calldata requestedClaims
    ) public whenStoreActive nonZeroQuantity(qty) {
        ItemDetail memory item = _validateItem(itemId, PaymentType.AWOO);
        _validateRequestedQuantity(itemId, item, qty);
        _ensureAvailablity(item, itemId, qty);

        _claimAwoo(requestedClaims);
        awooContract.spendVirtualAwoo(
            approval.Hash,
            approval.Sig,
            approval.Nonce,
            _msgSender(),
            qty * item.AWOOPrice
        );

        purchasedItemCount[itemId] += qty;
        ownedItemCountsByOwner[_msgSender()][itemId] += qty;
        emit ItemPurchased(itemId, _msgSender(), qty);
    }

    /// @notice Allows the specified item to be purchased with Ether
    /// @param itemId The id of the item to purchase
    /// @param qty The numbers of items to purchase
    function purchaseWithEth(uint16 itemId, uint256 qty)
        public
        payable
        whenStoreActive
        nonZeroQuantity(qty)
    {
        ItemDetail memory item = _validateItem(itemId, PaymentType.ETHER);
        _validateRequestedQuantity(itemId, item, qty);
        _ensureAvailablity(item, itemId, qty);
        _validateEtherValue(item, qty);

        purchasedItemCount[itemId] += qty;
        ownedItemCountsByOwner[_msgSender()][itemId] += qty;
        emit ItemPurchased(itemId, _msgSender(), qty);
    }

    /// @notice Allows the specified item to be purchased with AWOO and Ether, if the item allows it
    /// @param itemId The id of the item to purchase
    /// @param qty The number of items to purchase
    /// @param approval An object containing the signed message details authorizing us to spend the holders AWOO
    /// @param requestedClaims An optional array of ClaimDetails so we can automagically claim the necessary
    /// amount of AWOO, as specified through NFC
    function purchaseWithEthAndAwoo(
        uint16 itemId,
        uint256 qty,
        AwooSpendApproval calldata approval,
        ClaimDetails[] calldata requestedClaims
    ) public payable whenStoreActive nonZeroQuantity(qty) {
        ItemDetail memory item = _validateItem(
            itemId,
            PaymentType.AWOO_AND_ETHER
        );
        _validateRequestedQuantity(itemId, item, qty);
        _ensureAvailablity(item, itemId, qty);
        _validateEtherValue(item, qty);

        _claimAwoo(requestedClaims);
        awooContract.spendVirtualAwoo(
            approval.Hash,
            approval.Sig,
            approval.Nonce,
            _msgSender(),
            qty * item.AWOOPrice
        );

        purchasedItemCount[itemId] += qty;
        ownedItemCountsByOwner[_msgSender()][itemId] += qty;
        emit ItemPurchased(itemId, _msgSender(), qty);
    }

    /// @notice Allows the specified item to be purchased with AWOO and applied to the specified tokens
    /// @param itemId The id of the item to purchase
    /// @param approval An object containing the signed message details authorizing us to spend the holders AWOO
    /// @param requestedClaims An optional array of ClaimDetails so we can automagically claim the necessary
    /// amount of AWOO, as specified through NFC
    /// @param applicationTokenIds An array of supported token ids to apply the purchased items to
    function purchaseAndApplyWithAwoo(
        uint16 itemId,
        AwooSpendApproval calldata approval,
        ClaimDetails[] calldata requestedClaims,
        uint32[] calldata applicationTokenIds
    ) public whenStoreActive {
        ItemDetail memory item = _validateItem(itemId, PaymentType.AWOO);
        _validateRequestedQuantity(itemId, item, applicationTokenIds.length);
        _ensureAvailablity(item, itemId, applicationTokenIds.length);

        _claimAwoo(requestedClaims);
        awooContract.spendVirtualAwoo(
            approval.Hash,
            approval.Sig,
            approval.Nonce,
            _msgSender(),
            applicationTokenIds.length * item.AWOOPrice
        );

        purchasedItemCount[itemId] += applicationTokenIds.length;
        _applyItem(itemId, applicationTokenIds);
    }

    /// @notice Allows the specified item to be purchased with Ether and applied to the specified tokens
    /// @param itemId The id of the item to purchase
    /// @param applicationTokenIds An array of supported token ids to apply the purchased items to
    function purchaseAndApplyWithEth(
        uint16 itemId,
        uint32[] calldata applicationTokenIds
    ) public payable whenStoreActive {
        ItemDetail memory item = _validateItem(itemId, PaymentType.ETHER);
        _validateRequestedQuantity(itemId, item, applicationTokenIds.length);
        _validateEtherValue(item, applicationTokenIds.length);
        _ensureAvailablity(item, itemId, applicationTokenIds.length);

        purchasedItemCount[itemId] += applicationTokenIds.length;
        _applyItem(itemId, applicationTokenIds);
    }

    /// @notice Allows the specified item to be purchased with AWOO and Ether and applied
    /// @param itemId The id of the item to purchase
    /// @param approval An object containing the signed message details authorizing us to spend the holders AWOO
    /// @param requestedClaims An optional array of ClaimDetails so we can automagically claim the necessary
    /// amount of AWOO, as specified through NFC
    /// @param applicationTokenIds An array of supported token ids to apply the purchased items to
    function purchaseAndApplyWithEthAndAwoo(
        uint16 itemId,
        AwooSpendApproval calldata approval,
        ClaimDetails[] calldata requestedClaims,
        uint32[] calldata applicationTokenIds
    ) public payable whenStoreActive {
        ItemDetail memory item = _validateItem(
            itemId,
            PaymentType.AWOO_AND_ETHER
        );
        _validateRequestedQuantity(itemId, item, applicationTokenIds.length);
        _validateEtherValue(item, applicationTokenIds.length);
        _ensureAvailablity(item, itemId, applicationTokenIds.length);

        _claimAwoo(requestedClaims);
        awooContract.spendVirtualAwoo(
            approval.Hash,
            approval.Sig,
            approval.Nonce,
            _msgSender(),
            applicationTokenIds.length * item.AWOOPrice
        );

        purchasedItemCount[itemId] += applicationTokenIds.length;
        _applyItem(itemId, applicationTokenIds);
    }

    // TODO: Add the free mint/purchase functionality (V2)

    /// @notice Applies the specified item to the list of "upgradeable" tokens
    /// @param itemId The id of the item to apply
    /// @param applicationTokenIds An array of token ids to which the specified item will be applied
    function applyOwnedItem(
        uint16 itemId,
        uint32[] calldata applicationTokenIds
    ) public whenStoreActive {
        ItemDetail memory item = _getItem(itemId);
        require(
            applicationTokenIds.length <=
                ownedItemCountsByOwner[_msgSender()][itemId],
            "Exceeds owned quantity"
        );

        for (uint256 i; i < applicationTokenIds.length; i++) {
            _applyItem(item, itemId, applicationTokenIds[i]);
        }

        if (item.Burnable) {
            ownedItemCountsByOwner[_msgSender()][itemId] -= applicationTokenIds
                .length;
        }
    }

    /// @notice Allows the holder of a non-mintable item to "use" it for something (TBA) cool
    /// @param itemId The id of the item to use
    /// @param qty The number of items to use
    function useOwnedItem(uint16 itemId, uint256 qty)
        public
        whenStoreActive
        nonZeroQuantity(qty)
    {
        ItemDetail memory item = _getItem(itemId);
        require(item.Active, "Inactive item");
        require(
            qty <= ownedItemCountsByOwner[_msgSender()][itemId],
            "Exceeds owned quantity"
        );

        if (item.Burnable) {
            ownedItemCountsByOwner[_msgSender()][itemId] -= qty;
        }

        emit NonMintableItemUsed(itemId, _msgSender(), qty);
    }

    /// @notice Applies the specified item to the list of "upgradeable" tokens, and burns the item if applicable
    /// @dev Tokens can only be burned if the holder has explicitly allowed us to do so
    /// @param itemId The id of the item to apply
    /// @param applicationTokenIds An array of token ids to which the specified item will be applied
    function applyMintedItem(
        uint16 itemId,
        uint32[] calldata applicationTokenIds
    ) public whenStoreActive {
        ItemDetail memory item = _getItem(itemId);
        require(!item.NonMintable, "Specified item is not mintable");
        require(
            applicationTokenIds.length <=
                awooMintableCollectionContract.balanceOf(
                    _msgSender(),
                    item.TokenId
                ),
            "Invalid application qty"
        );

        for (uint256 i; i < applicationTokenIds.length; i++) {
            _applyItem(item, itemId, applicationTokenIds[i]);
        }

        if (item.Burnable) {
            awooMintableCollectionContract.burn(
                _msgSender(),
                item.TokenId,
                applicationTokenIds.length
            );
        }
    }

    function _applyItem(uint16 itemId, uint32[] calldata applicationTokenIds)
        private
    {
        ItemDetail memory item = _getItem(itemId);
        for (uint256 i; i < applicationTokenIds.length; i++) {
            _applyItem(item, itemId, applicationTokenIds[i]);
        }
    }

    function _applyItem(
        ItemDetail memory item,
        uint16 itemId,
        uint32 applicationTokenId
    ) private {
        require(item.UpgradeDetails.UpgradeItem, "Item cannot be applied");
        require(item.Active, "Inactive item");
        address collectionAddress = collectionIdAddressMap[
            item.UpgradeDetails.ApplicableCollectionId
        ];
        // Items can only be applied to "upgradable" tokens held by the same account
        require(
            _msgSender() ==
                ERC721Enumerable(collectionAddress).ownerOf(applicationTokenId),
            "Invalid application tokenId"
        );

        // Don't allow the item to be applied mutiple times to the same token unless the item is stackable
        if (!item.UpgradeDetails.Stackable) {
            require(
                tokenAppliedItemCountsByCollection[
                    item.UpgradeDetails.ApplicableCollectionId
                ][applicationTokenId][itemId] == 0,
                "Specified item already applied"
            );
        }

        // If the item should change the base AWOO accrual rate of the item that it is being applied to, do that
        // now
        if (item.UpgradeDetails.UpgradeBaseAccrualRate > 0) {
            awooClaimingContract.overrideTokenAccrualBaseRate(
                collectionAddress,
                applicationTokenId,
                item.UpgradeDetails.UpgradeBaseAccrualRate
            );
        }

        tokenAppliedItemCountsByCollection[
            item.UpgradeDetails.ApplicableCollectionId
        ][applicationTokenId][itemId] += 1;
        itemApplications[itemId][item.UpgradeDetails.ApplicableCollectionId]
            .push(applicationTokenId);

        // Tell NFC that we applied this upgrade so it can do some fun stuff
        emit UpgradeItemApplied(itemId, collectionAddress, applicationTokenId);
    }

    function _claimAwoo(ClaimDetails[] calldata requestedClaims) private {
        if (requestedClaims.length > 0) {
            awooClaimingContract.claim(_msgSender(), requestedClaims);
        }
    }

    function getItemApplications(uint16 itemId, uint8 applicableCollectionId)
        external
        view
        returns (uint256 count, uint256[] memory appliedToTokenIds)
    {
        count = itemApplications[itemId][applicableCollectionId].length;
        appliedToTokenIds = itemApplications[itemId][applicableCollectionId];
    }

    /// @notice Allows authorized individuals to add supported ERC721Enumerable collections
    function addCollection(address collectionAddress)
        external
        onlyOwnerOrAdmin
        returns (uint8 collectionId)
    {
        collectionId = ++collectionCount;
        collectionIdAddressMap[collectionId] = collectionAddress;
    }

    /// @notice Allows authorized individuals to remove supported ERC721Enumerable collections
    function removeCollection(uint8 collectionId) external onlyOwnerOrAdmin {
        require(collectionId <= collectionCount, "Invalid collectionId");
        delete collectionIdAddressMap[collectionId];
        collectionCount--;
    }

    /// @notice Allows authorized individuals to add new items
    function addItem(ItemDetail memory item, uint16 purchasedQty)
        external
        onlyOwnerOrAdmin
        returns (uint16)
    {
        _validateItem(item);

        if (!item.NonMintable && item.TokenId == 0) {
            uint256 tokenId = awooMintableCollectionContract.addToken(
                item.TokenDetails,
                item.MetadataUri
            );
            item.TokenId = tokenId;
        }

        itemIdDetailMap[++itemCount] = item;
        purchasedItemCount[itemCount] = purchasedQty;
        return itemCount;
    }

    /// @notice Allows authorized individuals to update an existing item
    function updateItem(
        uint16 itemId,
        ItemDetail memory newItem
    ) external onlyOwnerOrAdmin {
        _validateItem(newItem);
        ItemDetail memory existingItem = _getItem(itemId);
        require(
            existingItem.NonMintable == newItem.NonMintable,
            "Item mintability cannot change"
        );
        require(
            newItem.TotalAvailable <= _availableQty(existingItem, itemId),
            "Total exceeds available quantity"
        );

        if (!existingItem.NonMintable) {
            newItem.TokenId = existingItem.TokenId;

            if (
                bytes(newItem.MetadataUri).length !=
                bytes(existingItem.MetadataUri).length ||
                keccak256(abi.encodePacked(newItem.MetadataUri)) !=
                keccak256(abi.encodePacked(existingItem.MetadataUri))
            ) {
                awooMintableCollectionContract.setTokenUri(
                    existingItem.TokenId,
                    newItem.MetadataUri
                );
            }

            if (newItem.Active != existingItem.Active) {
                awooMintableCollectionContract.setTokenActive(
                    existingItem.TokenId,
                    newItem.Active
                );
            }
        }

        itemIdDetailMap[itemId] = newItem;
    }

    function _validateRequestedQuantity(
        uint16 itemId,
        ItemDetail memory item,
        uint256 requestedQty
    ) private view {
        require(
            _isWithinTransactionLimit(item, requestedQty),
            "Exceeds transaction limit"
        );
        require(
            _isWithinAddressLimit(itemId, item, requestedQty, _msgSender()),
            "Exceeds address limit"
        );
    }

    function _ensureAvailablity(
        ItemDetail memory item,
        uint16 itemId,
        uint256 requestedQty
    ) private view {
        require(
            requestedQty <= _availableQty(item, itemId),
            "Exceeds available quantity"
        );
    }

    function availableQty(uint16 itemId) public view returns (uint256) {
        ItemDetail memory item = _getItem(itemId);
        return _availableQty(item, itemId);
    }

    function _availableQty(ItemDetail memory item, uint16 itemId)
        private
        view
        returns (uint256)
    {
        uint256 mintedCount;

        // If the item is mintable, get the minted quantity from the ERC-1155 contract.
        // The minted count includes the quantity that was burned if the item does not have a soft limit
        if (!item.NonMintable) {
            mintedCount = awooMintableCollectionContract.totalMinted(
                item.TokenId
            );
        }
        return item.TotalAvailable - mintedCount - purchasedItemCount[itemId];
    }

    /// @notice Determines if the requested quantity is within the per-transaction limit defined by this item
    function _isWithinTransactionLimit(
        ItemDetail memory item,
        uint256 requestedQty
    ) private pure returns (bool) {
        if (item.PerTransactionLimit > 0) {
            return requestedQty <= item.PerTransactionLimit;
        }
        return true;
    }

    /// @notice Determines if the requested quantity is within the per-address limit defined by this item
    function _isWithinAddressLimit(
        uint16 itemId,
        ItemDetail memory item,
        uint256 requestedQty,
        address recipient
    ) private view returns (bool) {
        if (item.PerAddressLimit > 0) {
            uint256 tokenCountByOwner = item.NonMintable
                ? ownedItemCountsByOwner[recipient][itemId]
                : ownedItemCountsByOwner[recipient][itemId] +
                    mintedItemCountsByAddress[recipient][itemId];

            return tokenCountByOwner + requestedQty <= item.PerAddressLimit;
        }
        return true;
    }

    /// @notice Returns an array of tokenIds and application counts to indicate how many of the specified items
    /// were applied to the specified tokenIds
    function checkItemTokenApplicationStatus(
        uint8 collectionId,
        uint16 itemId,
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory checkedTokenIds = new uint256[](tokenIds.length);
        uint256[] memory applicationCounts = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = uint32(tokenIds[i]);

            checkedTokenIds[i] = tokenId;
            applicationCounts[i] = tokenAppliedItemCountsByCollection[
                collectionId
            ][tokenId][itemId];
        }

        return (checkedTokenIds, applicationCounts);
    }

    function _validateEtherValue(ItemDetail memory item, uint256 qty) private {
        require(msg.value == item.EtherPrice * qty, "Incorrect amount");
    }

    function _getItem(uint16 itemId)
        private
        view
        returns (ItemDetail memory item)
    {
        require(itemId <= itemCount, "Invalid itemId");
        item = itemIdDetailMap[itemId];
    }

    function _validateItem(uint16 itemId, PaymentType paymentType)
        private
        view
        returns (ItemDetail memory item)
    {
        item = _getItem(itemId);
        require(item.Active, "Inactive item");
        require(item.PmtType == paymentType, "Invalid item for payment type");
    }

    function _validateItem(ItemDetail memory item) private view {
        require(item.TotalAvailable > 0, "Total available cannot be zero");
        require(
            !(item.UpgradeDetails.Stackable && item.PerAddressLimit == 1),
            "Invalid per-address limit"
        );

        if (!item.NonMintable) {
            require(
                bytes(item.MetadataUri).length > 0,
                "Item requires a metadata uri"
            );
        }

        if (item.UpgradeDetails.UpgradeItem) {
            require(
                item.UpgradeDetails.ApplicableCollectionId <= collectionCount,
                "Invalid applicableCollectionId"
            );
        } else {
            require(
                item.UpgradeDetails.ApplicableCollectionId == 0,
                "Invalid applicableCollectionId"
            );
        }

        if (item.PmtType == PaymentType.ETHER) {
            require(item.EtherPrice > 0, "Invalid ether price");
            require(item.AWOOPrice == 0, "Invalid AWOO price");
        } else if (item.PmtType == PaymentType.AWOO) {
            require(item.EtherPrice == 0, "Invalid ether price");
            require(
                item.AWOOPrice == ((item.AWOOPrice / 1e18) * 1e18),
                "Invalid AWOO price"
            );
        } else if (item.PmtType == PaymentType.AWOO_AND_ETHER) {
            require(item.EtherPrice > 0, "Invalid ether price");
            require(
                item.AWOOPrice == ((item.AWOOPrice / 1e18) * 1e18),
                "Invalid AWOO price"
            );
        }
        // free
        else {
            revert("Not implemented, yet");
        }
    }

    /// @notice Allows authorized individuals to swap out claiming contract
    function setAwooClaimingContract(IAwooClaimingV2 awooClaiming)
        external
        onlyOwnerOrAdmin
    {
        awooClaimingContract = IAwooClaimingV2(awooClaiming);
    }

    /// @notice Allows authorized individuals to swap out the ERC-1155 collection contract, if absolutely necessary
    function setAwooCollection(IAwooMintableCollection awooCollectionContract)
        external
        onlyOwnerOrAdmin
    {
        awooMintableCollectionContract = awooCollectionContract;
    }

    /// @notice Allows authorized individuals to swap out the ERC-20 AWOO contract, if absolutely necessary
    function setAwooTokenContract(IAwooToken awooTokenContract)
        external
        onlyOwnerOrAdmin
    {
        awooContract = awooTokenContract;
    }

    /// @notice Allows authorized individuals to activate/deactivate this contract
    function setActive(bool active) external onlyOwnerOrAdmin {
        if (active) {
            require(
                address(awooMintableCollectionContract) != address(0),
                "Awoo collection has not been set"
            );
        }
        storeActive = active;
    }

    /// @notice Allows authorized individuals to activate/deactivate specific items
    function setItemActive(uint16 itemId, bool isActive)
        external
        onlyOwnerOrAdmin
    {
        require(itemId > 0 && itemId <= itemCount, "Invalid Item Id");

        itemIdDetailMap[itemId].Active = isActive;
    }

    /// @notice Allows authorized individuals to specify which address Ether and other arbitrary ERC-20 tokens
    /// should be sent to during withdraw
    function setWithdrawAddress(address payable addr)
        external
        onlyOwnerOrAdmin
    {
        require(addr != address(0), "Invalid address");
        withdrawAddress = addr;
    }

    function withdraw(uint256 amount) external onlyOwnerOrAdmin {
        require(amount <= address(this).balance, "Amount exceeds balance");
        require(payable(withdrawAddress).send(amount), "Sending failed");
    }

    /// @dev Any random ERC-20 tokens sent to this contract will be locked forever, unless we rescue them
    function rescueArbitraryERC20(IERC20 token) external {
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "Contract has no balance");
        require(
            token.transfer(payable(withdrawAddress), balance),
            "Transfer failed"
        );
    }

    modifier nonZeroQuantity(uint256 qty) {
        require(qty > 0, "Quantity cannot be zero");
        _;
    }

    modifier whenStoreActive() {
        require(storeActive, "Awoo Store is not active");
        _;
    }
}