// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ICollection.sol";

contract OpenEdition is Ownable {

    using Address for address;

    uint256 private constant _ONE_HUNDRED_PERCENT = 10000; // 100%

    event SessionCreated(uint256 sessionId, address[] accounts, uint256 commission, uint256 start, uint256 end);
    event SessionRemoved(uint256 sessionId);

    event CommissionReceiverChanged(address account);
    event CommissionChanged(uint256 sessionId, uint256 commission);

    event TokenMetadataCreated(uint256 sessionId, uint256 tokenId, uint256 price, uint256 royalty, string uri);
    event TokenMetadataUpdated(uint256 sessionId, uint256 tokenId, uint256 price, uint256 royalty, string uri);
    event TokenPriceUpdated(uint256 tokenId, uint256 price);

    event TokenBought(uint256 sessionId, uint256 tokenId, address account, uint256 price, uint256 commission);

    ICollection private _collection;

    uint256 private _totalSessions;
    uint256 private _maxSessions = 0; // 0 = No Limit, >0 = has limit based on the number

    struct Session {
        mapping(address => bool) whitelisted;
        address[] creators;
        uint256 commission;
        uint256 start;
        uint256 end;
        uint256[] tokenIds;
    }

    mapping(uint256 => Session) private _sessions;

    // Mapping from token ID to prices
    mapping(uint256 => uint256) private _prices;

    address payable private _commissionReceiver;

    /**
     * @dev Initializes the contract settings
     */
    constructor(address collection, address payable feeReceiver, uint256 maxSessions)
    {
        _collection = ICollection(collection);
        _commissionReceiver = feeReceiver;
        _maxSessions = maxSessions;
    }

    /**
     * @dev Returns Collection smart contract address
     */
    function collectionContract()
        public
        view
        returns (address)
    {
        return address(_collection);
    }

    /**
     * @dev Returns total sessions
     */
    function totalSessions()
        public
        view
        returns (uint256)
    {
        return _totalSessions;
    }

    /**
     * @dev Creates a session
     */
    function createSession(uint256 sessionId, address[] memory accounts, uint256 commission, uint256 start, uint256 end)
        public
        onlyOwner
    {
        require(_maxSessions == 0 || _totalSessions < _maxSessions, "OpenEdition: max session reached");
        require(_sessions[sessionId].start == 0, "OpenEdition: session already exists");
        require(start < end && start > 0 && end > 0, "OpenEdition: invalid start time or end time");

        for (uint256 i = 0; i < accounts.length; i++) {
            address creator = accounts[i];
            require(creator != address(0) && !creator.isContract() && !_sessions[sessionId].whitelisted[creator], "OpenEdition: can't create session");
            require(_collection.isMinter(creator), "OpenEdition: not all accounts are minters");

            _sessions[sessionId].whitelisted[creator] = true;
        }

        require(commission <= _ONE_HUNDRED_PERCENT, "OpenEdition: params is invalid");

        _sessions[sessionId].commission = commission;
        _sessions[sessionId].creators = accounts;
        _sessions[sessionId].start = start;
        _sessions[sessionId].end = end; 

        _totalSessions++;

        emit SessionCreated(sessionId, accounts, commission, start, end);
    }

    /**
     * @dev Removes a session
     */
    function removeSession(uint256[] memory sessionIds)
        public
        onlyOwner
    {
        uint256 cnt = 0;

        for (; cnt < sessionIds.length; cnt++) {
            uint256 id = sessionIds[cnt];

            require(_sessions[id].start > 0 && block.timestamp < _sessions[id].start , "OpenEdition: can not remove session");

            delete _sessions[id];

            cnt++;

            emit SessionRemoved(id);
        }

        if (cnt > 0) {
            _totalSessions -= cnt;
        }
    }

    /**
     * @dev Changes commission
     */
    function changeCommission(uint256 sessionId, uint256 commission)
        public
        onlyOwner
    {
        require(_sessions[sessionId].start > 0 && block.timestamp < _sessions[sessionId].end, "OpenEdition: can not change");

        require(commission <= _ONE_HUNDRED_PERCENT, "OpenEdition: commission is invalid");

        _sessions[sessionId].commission = commission;

        emit CommissionChanged(sessionId, commission);
    }

    /**
     * @dev Returns session information
     */
    function session(uint256 sessionId)
        public
        view
        returns (address[] memory, uint256, uint256[] memory, uint256, uint256)
    {
        
        return (_sessions[sessionId].creators, _sessions[sessionId].commission, _sessions[sessionId].tokenIds, _sessions[sessionId].start, _sessions[sessionId].end);
    }

    /**
     * @dev Function to set the commission receiver
     */
    function changeCommissionReceiver(address payable account)
        public
        onlyOwner
    {
        require(account != address(0), "OpenEdition: address is invalid");

        _commissionReceiver = account;

        emit CommissionReceiverChanged(account);
    }

    /**
     * @dev Returns the address of commission receiver
     */
    function commissionReceiver()
        public
        view
        returns (address)
    {
        return _commissionReceiver;
    }

    /**
     * @dev Returns token information
     */
    function token(uint256 tokenId)
        public
        view
        returns (uint256, uint256, string memory, address, uint256)
    {
        return (_prices[tokenId], _collection.royalty(tokenId), _collection.uri(tokenId), _collection.creator(tokenId), _collection.totalSupply(tokenId));
    }

    /**
     * @dev Creates token metadata
     */
    function createTokenMetadata(uint256 sessionId, uint256 price, uint256 royalty, string memory uri)
        public
    {
        address creator = _msgSender();

        require(_sessions[sessionId].whitelisted[creator] == true && block.timestamp < _sessions[sessionId].start, "OpenEdition: can not create token metadata");

        uint256 tokenId = _collection.generateTokenId();

        _sessions[sessionId].tokenIds.push(tokenId);

        _prices[tokenId] = price;

        _collection.updateTokenMetadata(tokenId, creator, royalty, uri);

        emit TokenMetadataCreated(sessionId, tokenId, price, royalty, uri);
    }

    /**
     * @dev Updates token metadata
     */
    function updateTokenMetadata(uint256 sessionId, uint256 tokenId, uint256 price, uint256 royalty, string memory uri)
        public
    {
        address creator = _msgSender();

        require(_sessions[sessionId].whitelisted[creator] == true && block.timestamp < _sessions[sessionId].start, "OpenEdition: can not update token metadata");

        bool exist = false;

        uint256[] memory tokens = _sessions[sessionId].tokenIds;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                exist = true;
                break;
            }
        }

        require(exist, "OpenEdition: tokenId is invalid");

        if (_prices[tokenId] != price) {
            _prices[tokenId] = price;
        }

        _collection.updateTokenMetadata(tokenId, creator, royalty, uri);

        emit TokenMetadataUpdated(sessionId, tokenId, price, royalty, uri);
    }

    /**
     * @dev Updates token price
     */
    function updateTokenPrice(uint256 tokenId, uint256 price)
        public
        onlyOwner
    {
        _prices[tokenId] = price;

        emit TokenPriceUpdated(tokenId, price);
    }

    /**
     * @dev Buys token
     */
    function buyToken(uint256 sessionId, uint256 tokenId)
        public
        payable
    {
        uint256 price = _prices[tokenId];

        require(_sessions[sessionId].start < block.timestamp && block.timestamp < _sessions[sessionId].end && price == msg.value, "OpenEdition: can not buy token");

        address msgSender = _msgSender();

        require(!msgSender.isContract(), "OpenEdition: caller is invalid");

        uint256 percentage = _sessions[sessionId].commission;

        uint256 commission = price * percentage / _ONE_HUNDRED_PERCENT;

        if (commission > 0) {
            _commissionReceiver.transfer(commission);
        }

        if (price > 0 && price > commission) {
            payable(_collection.creator(tokenId)).transfer(price - commission);
        }

        _collection.mint(msgSender, tokenId, 1, "");

        emit TokenBought(sessionId, tokenId, msgSender, price, percentage);
    }

}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICollectionCore.sol";

interface ICollection is ICollectionCore {
    function areMinters(address[] memory accounts) external view returns (bool);
    function getMetadataByTokenIds(uint256[] memory tokenIds) external view returns (string[] memory, address[] memory, uint256[] memory, uint256[] memory);
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

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface ICollectionCore is IERC165, IERC1155, IERC1155MetadataURI {
    event MinterUpdated(address account, bool status);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function setTokenURIPrefix() external;
    function tokenURIPrefix() external view returns (string memory);
    function updateMinters(address[] memory accounts, bool status) external;
    function isMinter(address account) external returns (bool);
    function updateTokenMetadata(uint256 tokenId, address _creator, uint256 _royalty, string memory _uri) external;
    function creator(uint256 tokenId) external view returns (address);
    function royalty(uint256 tokenId) external view returns (uint256);
    function totalSupply(uint256 tokenId) external view returns (uint256);
    function generateTokenId() external returns (uint256);
    function mint(address account, uint256 tokenId, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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