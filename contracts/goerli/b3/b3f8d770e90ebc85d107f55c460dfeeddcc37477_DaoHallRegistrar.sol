/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/registrar/ens/ENS.sol

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


// File contracts/registrar/ens/IBaseRegistrar.sol

interface IBaseRegistrar is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(uint256 indexed id, uint256 expires);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns (uint256);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256);

    function renew(uint256 id, uint256 duration) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}


// File contracts/registrar/ens/IMetadataService.sol

pragma solidity >=0.8.4;

interface IMetadataService {
    function uri(uint256) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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


// File contracts/registrar/ens/INameWrapper.sol


pragma solidity ^0.8.4;




uint32 constant CANNOT_UNWRAP = 1;
uint32 constant CANNOT_BURN_FUSES = 2;
uint32 constant CANNOT_TRANSFER = 4;
uint32 constant CANNOT_SET_RESOLVER = 8;
uint32 constant CANNOT_SET_TTL = 16;
uint32 constant CANNOT_CREATE_SUBDOMAIN = 32;
uint32 constant PARENT_CANNOT_CONTROL = 64;
uint32 constant CAN_DO_EVERYTHING = 0;

interface INameWrapper is IERC1155 {
    event NameWrapped(
        bytes32 indexed node,
        bytes name,
        address owner,
        uint32 fuses,
        uint64 expiry
    );

    event NameUnwrapped(bytes32 indexed node, address owner);

    event FusesSet(bytes32 indexed node, uint32 fuses, uint64 expiry);

    function ens() external view returns (ENS);

    function registrar() external view returns (IBaseRegistrar);

    function metadataService() external view returns (IMetadataService);

    function names(bytes32) external view returns (bytes memory);

    function wrap(
        bytes calldata name,
        address wrappedOwner,
        address resolver
    ) external;

    function wrapETH2LD(
        string calldata label,
        address wrappedOwner,
        uint32 fuses,
        uint64 _expiry,
        address resolver
    ) external returns (uint64 expiry);

    function registerAndWrapETH2LD(
        string calldata label,
        address wrappedOwner,
        uint256 duration,
        address resolver,
        uint32 fuses,
        uint64 expiry
    ) external returns (uint256 registrarExpiry);

    function renew(
        uint256 labelHash,
        uint256 duration,
        uint64 expiry
    ) external returns (uint256 expires);

    function unwrap(
        bytes32 node,
        bytes32 label,
        address owner
    ) external;

    function unwrapETH2LD(
        bytes32 label,
        address newRegistrant,
        address newController
    ) external;

    function setFuses(bytes32 node, uint32 fuses)
        external
        returns (uint32 newFuses);

    function setChildFuses(
        bytes32 parentNode,
        bytes32 labelhash,
        uint32 fuses,
        uint64 expiry
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external;

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        string calldata label,
        address newOwner,
        uint32 fuses,
        uint64 expiry
    ) external returns (bytes32);

    function isTokenOwnerOrApproved(bytes32 node, address addr)
        external
        returns (bool);

    function setResolver(bytes32 node, address resolver) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function ownerOf(uint256 id) external returns (address owner);

    function allFusesBurned(bytes32 node, uint32 fuseMask)
        external
        view
        returns (bool);
}


// File contracts/registrar/ens/NameWrapper.sol


pragma solidity ^0.8.4;
interface NameWrapper is INameWrapper {

  function getData(uint256 tokenId) external view
        returns (
            address owner,
            uint32 fuses,
            uint64 expiry
        );
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File contracts/registrar/DaoHallRegistrar.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
uint32 constant FLAG_AVAILABLE = 1;
uint32 constant FLAG_LOCKED = 2;

error PriceLocked(bytes32 node, uint i);
error PriceAlreadyAvailable(bytes32 node, uint i);
error PirceNotAvailable(bytes32 node, uint i);

contract DaoHallRegistrar is Ownable{
  using Address for address;

  bytes32 private constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

  struct NodeRecord{
    address setter;
    uint256 startTime;
    uint256[5] annualPrice;
    uint256[5] maxPrice;

    uint256 whitelistStartTime;
    uint256 whitelistParam;
    bytes32 whitelistRoot;
  }

  NameWrapper public wrapper;
  ENS public immutable ens;
  IBaseRegistrar public immutable registrar;
  uint32 public immutable feeRate = 250;
  address public feeReceiver;

  mapping(bytes32 => NodeRecord) private _nodeRecords;
  mapping(bytes32 => mapping(address => uint32)) private _whitelistRecords;
  mapping(bytes32 => uint256) private _subnodeExpiries;

  event NodeUpdated(bytes32 node, address operator);
  event SubnodeSale(string label, bytes32 parentNode, address buyer, uint32 duration, uint256 price);
  event SubnodeExtended(string label, bytes32 parentNode, address buyer, uint32 duration, uint256 price);

  // Permits modifications only by the owner of the specified node.
  modifier authorised(bytes32 labelhash) {
    address owner = wrapper.ownerOf(uint256(_makeNode(ETH_NODE, labelhash)));
    if(owner != address(0)){
      require(owner == msg.sender || wrapper.isApprovedForAll(owner, msg.sender), "Unauthorised");
    }
    else{
      owner = registrar.ownerOf(uint256(labelhash));
      require(owner == msg.sender || registrar.isApprovedForAll(owner, msg.sender), "Unauthorised");
    }
    _;
  }

  constructor(
    NameWrapper _wrapper,
    ENS _ens,
    IBaseRegistrar _registrar,
    address _feeReceiver
  ) {
    wrapper = _wrapper;
    ens = _ens;
    registrar = _registrar;
    feeReceiver = _feeReceiver;
  }
  
  function setNameWrapper(NameWrapper _wrapper) external onlyOwner {
    wrapper = _wrapper;
  }

  function _setPrice(bytes32 node, uint256 startTime, uint256[5] calldata annualPrice, uint256[5] calldata maxPrice) internal{
    _nodeRecords[node].setter = msg.sender;
    _nodeRecords[node].startTime = startTime;
    uint i = 0;
    for(i = 0; i < 5; i ++){
      if(isLocked(_nodeRecords[node].annualPrice[i])){
        // record locked
        if(_nodeRecords[node].annualPrice[i] != annualPrice[i] || _nodeRecords[node].maxPrice[i] != maxPrice[i]){
          revert PriceLocked(node, i);
        }
        continue;
      }
      if(isAvailable(_nodeRecords[node].annualPrice[i]) && !isAvailable(annualPrice[i])){
        revert PriceAlreadyAvailable(node, i);
      }
      if(isAvailable(_nodeRecords[node].maxPrice[i]) && !isAvailable(maxPrice[i])){
        revert PriceAlreadyAvailable(node, i);
      }
      _nodeRecords[node].annualPrice[i] = annualPrice[i];
      _nodeRecords[node].maxPrice[i] = maxPrice[i];
    }
  }

  function _setWhitelist(bytes32 node, uint256 startTime, uint256 param, bytes32 root) internal{
    _nodeRecords[node].setter = msg.sender;
    _nodeRecords[node].whitelistStartTime = startTime;
    _nodeRecords[node].whitelistParam = param;
    _nodeRecords[node].whitelistRoot = root;
  }

  function setPrice(bytes32 labelhash, uint256 startTime, uint256[5] calldata annualPrice, uint256[5] calldata maxPrice) external authorised(labelhash){
    bytes32 node = _makeNode(ETH_NODE, labelhash);
    _setPrice(node, startTime, annualPrice, maxPrice);
    emit NodeUpdated(node, msg.sender);
  }

  function setWhitelist(bytes32 labelhash, uint256 startTime, uint256 param, bytes32 root) external authorised(labelhash){
    bytes32 node = _makeNode(ETH_NODE, labelhash);
    _setWhitelist(node, startTime, param, root);
    emit NodeUpdated(node, msg.sender);
  }

  function setRecord(bytes32 labelhash, NodeRecord calldata record) external authorised(labelhash) {
    bytes32 node = _makeNode(ETH_NODE, labelhash);
    _setPrice(node, record.startTime, record.annualPrice, record.maxPrice);
    _setWhitelist(node, record.whitelistStartTime, record.whitelistParam, record.whitelistRoot);
    emit NodeUpdated(node, msg.sender);
  }

  function getRecord(bytes32 node) public view returns (NodeRecord memory) {
    return _nodeRecords[node];
  }

  function whitelistClaimed(bytes32 node, address claimer) public view returns (uint32){
    return _whitelistRecords[node][claimer];
  }

  function buySubnode(string memory label, bytes32 parentNode, address resolver, uint64 ttl, uint32 fuses, uint32 duration) external payable {
    _checkBuy(label, parentNode, duration);
    _buy(label, parentNode, resolver, ttl, fuses, msg.value, duration);
  }

  function buySubnodeWhitelisted(string memory label, bytes32 parentNode, address resolver, uint64 ttl, uint32 fuses, bytes32[] calldata proof, uint64 data) external payable {
    uint32 limit = uint32(data >> 32);
    uint32 duration = uint32(data);
    _checkBuyWhitelisted(label, parentNode, duration, proof, limit);
    _buy(label, parentNode, resolver, ttl, fuses, msg.value, duration);
  }

  function extendSubnode(string memory label, bytes32 parentNode, uint32 duration) external payable {
    // check for subnode
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 node = _makeNode(parentNode, labelhash);
    (address owner, uint32 fuses, uint64 oldExpiry) = wrapper.getData(uint256(node));
    require(owner != address(0), "No such subnode");

    uint256 price = _calculatePrice(parentNode, unicodeLength(label), duration);
    require(msg.value == price, "Invalid price");

    (address parentOwner, , uint64 parentExpiry) = wrapper.getData(uint256(parentNode));
    uint64 newExpiry = parentExpiry;    
    if(duration > 0){
      newExpiry = uint64(oldExpiry + (duration * 365 days));
      require(newExpiry <= parentExpiry, "Invalid duration");
    }

    _processFee(price, parentOwner);
    wrapper.setChildFuses(parentNode, labelhash, fuses, newExpiry);
    emit SubnodeExtended(label, parentNode, msg.sender, duration, price);
  }

  function registerSubnodeEns(string memory label, bytes32 parentHash, address resolver, uint64 ttl, uint32 fuses, uint32 duration) external {
    require(msg.sender == _ownerOfEns(parentHash), "Not owner");
    require(unicodeLength(label) > 0, "Empty label");
    _buyEns(label, parentHash, resolver, ttl, fuses, 0, duration);
  }

  function buySubnodeEns(string memory label, bytes32 parentHash, address resolver, uint64 ttl, uint32 fuses, uint32 duration) external payable {
    bytes32 parentNode = _makeNode(ETH_NODE, parentHash);
    _checkBuy(label, parentNode, duration);
    _buyEns(label, parentHash, resolver, ttl, fuses, msg.value, duration);
  }

  function buySubnodeWhitelistedEns(string memory label, bytes32 parentHash, address resolver, uint64 ttl, uint32 fuses, bytes32[] calldata proof, uint64 data) external payable {
    uint32 limit = uint32(data >> 32);
    uint32 duration = uint32(data);
    bytes32 parentNode = _makeNode(ETH_NODE, parentHash);
    _checkBuyWhitelisted(label, parentNode, duration, proof, limit);
    _buyEns(label, parentHash, resolver, ttl, fuses, msg.value, duration);
  }

  function extendSubnodeEns(string memory label, bytes32 parentHash, uint32 duration) external payable {
    // check for subnode
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 parentNode = _makeNode(ETH_NODE, parentHash);
    bytes32 node = _makeNode(parentNode, labelhash);
    address owner = _ownerOfEns(parentHash);
    uint256 oldExpiry = _subnodeExpiries[node];
    require(owner != address(0), "No such subnode");

    uint256 price = _calculatePrice(parentNode, unicodeLength(label), duration);
    address parentOwner = _ownerOfEns(parentHash);
    require(msg.value == price || msg.sender == parentOwner, "Invalid price");

    // check expiry
    
    uint256 parentExpiry = registrar.nameExpires(uint256(parentHash));
    uint256 newExpiry = parentExpiry;    
    if(duration > 0){
      newExpiry = oldExpiry + (duration * 365 days);
      require(newExpiry <= parentExpiry, "Invalid duration");
    }

    if(price > 0){
      _processFee(price, parentOwner);
    }
    _subnodeExpiries[node] = newExpiry;
    emit SubnodeExtended(label, parentNode, msg.sender, duration, price);
  }

  function wrapSubnode(string memory label, bytes32 parentNode) external {
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 node = _makeNode(parentNode, labelhash);
    address owner = ens.owner(node);
    require(owner == msg.sender || ens.isApprovedForAll(owner, msg.sender), "Unauthorised");

    wrapper.setSubnodeRecord(parentNode, label, owner, ens.resolver(node), ens.ttl(node), 0, uint64(_subnodeExpiries[node]));
  }

  function _calculatePrice(bytes32 node, uint256 length, uint32 duration) internal view returns (uint256) {
    uint256 index = length > 5 ? 4 : length - 1;
    uint256 price = duration == 0 ? _nodeRecords[node].maxPrice[index] : _nodeRecords[node].annualPrice[index];
    if(!isAvailable(price)){
      revert PirceNotAvailable(node, index);
    }
    price = getValue(price);
    return duration > 0 ? price * duration : price;
  }

  function _checkBuy(string memory label, bytes32 parentNode, uint32 duration) internal {
    require(_nodeRecords[parentNode].startTime > 0 && _nodeRecords[parentNode].startTime <= block.timestamp, "Not for sale");
    uint256 len = unicodeLength(label);
    require(len > 0, "Empty label");
    
    // check amount
    uint256 price = _calculatePrice(parentNode, len, duration);
    require(msg.value == price, "Invalid price");
  }

  function _checkBuyWhitelisted(string memory label, bytes32 parentNode, uint32 duration, bytes32[] calldata proof, uint32 limit) internal {
    require(_nodeRecords[parentNode].whitelistStartTime > 0 && _nodeRecords[parentNode].whitelistStartTime <= block.timestamp, "Not for sale");
    require(bytes(label).length > 0, "Empty label");
    require(_whitelistRecords[parentNode][msg.sender] < limit, "Address has claimed");

    uint16 maxDuration = whitelistMaxDuration(_nodeRecords[parentNode].whitelistParam);
    require(maxDuration == 0 || (duration > 0 && duration <= maxDuration), "Exceed Max Duration");
    
    // check amount
    uint256 price =  _calculatePrice(parentNode, unicodeLength(label), duration);
    price = price * (100 - whitelistDiscount(_nodeRecords[parentNode].whitelistParam))/100;
    require(msg.value == price, "Invalid price");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, bytes4(limit)));
    require(MerkleProof.verify(proof, _nodeRecords[parentNode].whitelistRoot, leaf), "Invalid proof");
    _whitelistRecords[parentNode][msg.sender] ++;
  }

  function _checkAvailability(string memory label, bytes32 parentNode) internal view {
    // check availability
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 node = _makeNode(parentNode, labelhash);
    (address owner, , uint64 expiry) = wrapper.getData(uint256(node));
    require(owner == address(0) || expiry < block.timestamp, "Subnode not available");
  }

  function _buy(string memory label, bytes32 parentNode, address resolver, uint64 ttl, uint32 fuses, uint256 price, uint32 duration) internal{
    // check availability
    _checkAvailability(label, parentNode);

    // check expiry date
    (address parentOwner, , uint64 parentExpiry) = wrapper.getData(uint256(parentNode));
    uint64 childExpiry = parentExpiry;
    if(duration > 0){
      childExpiry = uint64(block.timestamp + (duration * 365 days));
      require(childExpiry <= parentExpiry, "Invalid duration");
    }
    
    _processFee(price, parentOwner);
    wrapper.setSubnodeRecord(parentNode, label, msg.sender, resolver, ttl, fuses, childExpiry);
    emit SubnodeSale(label, parentNode, msg.sender, duration, price);
  }

  function _checkAvailabilityEns(bytes32 node) internal view {
    address owner = ens.owner(node);
    uint256 expiry = _subnodeExpiries[node];
    require(owner == address(0) || expiry < block.timestamp, "Subnode not available");
  }

  function _ownerOfEns(bytes32 labelhash) internal view returns (address){
    return registrar.ownerOf(uint256(labelhash));
  }
  
  function _buyEns(string memory label, bytes32 parentHash, address resolver, uint64 ttl, uint32, uint256 price, uint32 duration) internal{
    // check availability
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 parentNode = _makeNode(ETH_NODE, parentHash);
    bytes32 node = _makeNode(parentNode, labelhash);
    _checkAvailabilityEns(node);

    // check expiry date
    uint64 parentExpiry = uint64(registrar.nameExpires(uint256(parentHash)));
    uint64 childExpiry = parentExpiry;
    if(duration > 0){
      childExpiry = uint64(block.timestamp + (duration * 365 days));
      require(childExpiry <= parentExpiry, "Invalid duration");
    }
    
    if(price > 0){
      address parentOwner = _ownerOfEns(parentHash);
      _processFee(price, parentOwner);
    }
    ens.setSubnodeRecord(parentNode, labelhash, msg.sender, resolver, ttl);
    _subnodeExpiries[node] = childExpiry;
    emit SubnodeSale(label, parentNode, msg.sender, duration, price);
  }

  function getNodeDataEns(bytes32 node) public view returns (address owner, uint256 expiry) {
    owner = ens.owner(node);
    expiry = _subnodeExpiries[node];
  }

  function _processFee(uint256 price, address owner) internal {
    uint256 fee = price * feeRate / 10000;
    uint256 amount = price - fee;
    Address.sendValue(payable(owner), amount);
    Address.sendValue(payable(feeReceiver), fee);
  }

  function _makeNode(bytes32 node, bytes32 labelhash) private pure returns (bytes32){
    return keccak256(abi.encodePacked(node, labelhash));
  }

  function setFeeReceiver(address _feeReceiver) external onlyOwner {
    feeReceiver = _feeReceiver;
  }

  function withdraw(uint256 amount, address receiver) external onlyOwner {
    Address.sendValue(payable(receiver), amount);
  }

  function getValue(uint256 price) public pure returns (uint256){
    return uint224(price);
  }

  function isAvailable(uint256 price) public pure returns(bool){
    return hasFlag(price, FLAG_AVAILABLE);
  }

  function isLocked(uint256 price) public pure returns (bool){
    return hasFlag(price, FLAG_LOCKED);
  }

  function hasFlag(uint256 price, uint32 flag) public pure returns (bool){
    return (uint32(price >> 224) & flag) > 0;
  }

  function whitelistDiscount(uint256 param) public pure returns (uint16){
    return uint16(param);
  }

  function whitelistMaxDuration(uint256 param) public pure returns (uint16){
    return uint16(param >> 16);
  }

  function unicodeLength(string memory str) public pure returns (uint256){
    // uint256 len = bytes(str).length;
    bytes memory bs = bytes(str);
    uint256 len = bs.length;
    uint256 i = 0;
    uint256 result = 0;
    while(i < len){
        result ++;
        uint8 ch = uint8(bs[i]);
        if(ch < 0x80){
            i ++;
        }
        else if(ch < 0xe0){
            i += 2;
        }
        else if(ch < 0xf0){
            i += 3;
        }
        else{
            i += 4;
        }
    }
    return result;
  }
}