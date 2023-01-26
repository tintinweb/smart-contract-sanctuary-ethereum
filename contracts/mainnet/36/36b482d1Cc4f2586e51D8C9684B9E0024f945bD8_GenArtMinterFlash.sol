// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccess is Ownable {
    mapping(address => bool) public admins;
    address public genartAdmin;

    constructor() Ownable() {
        genartAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the GEN.ART admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genartAdmin == sender,
            "GenArtAccess: caller is not genart admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genartAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../storage/GenArtStorage.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtMinter.sol";
import "../factory/GenArtCollectionFactory.sol";
import "../factory/GenArtPaymentSplitterFactory.sol";

/**
 * @dev GEN.ART Curated
 * Admin of {GenArtCollectionFactory} and {GenArtPaymentSplitterFactory}
 */

struct CreateCollectionParams {
    address artist;
    string name;
    string symbol;
    string script;
    uint8 collectionType;
    uint256 maxSupply;
    uint8 erc721Index;
    uint8 pricingMode;
    bytes pricingData;
    uint8 paymentSplitterIndex;
    address[] payeesMint;
    address[] payeesRoyalties;
    uint256[] sharesMint;
    uint256[] sharesRoyalties;
}
struct PricingParams {
    uint8 mode;
    bytes data;
}

struct CollectionInfo {
    string name;
    string symbol;
    address minter;
    Collection collection;
    Artist artist;
}

contract GenArtCurated is GenArtAccess {
    address public collectionFactory;
    address public paymentSplitterFactory;
    GenArtStorage public store;
    mapping(uint8 => address) public minters;

    event ScriptUpdated(address collection, string script);

    constructor(
        address collectionFactory_,
        address paymentSplitterFactory_,
        address store_
    ) {
        collectionFactory = collectionFactory_;
        paymentSplitterFactory = paymentSplitterFactory_;
        store = GenArtStorage(payable(store_));
    }

    /**
     * @dev Internal functtion to close the ERC721 implementation contract
     */
    function _cloneCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        return
            GenArtCollectionFactory(collectionFactory).cloneCollectionContract(
                params
            );
    }

    /**
     * @dev Internal functtion to create the collection and risgister to minter
     */
    function _createCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        (instance, id) = _cloneCollection(params);
        store.setCollection(
            Collection(
                id,
                params.artist,
                instance,
                params.maxSupply,
                params.script,
                params.paymentSplitter
            )
        );
    }

    /**
     * @dev Clones an ERC721 implementation contract
     * @param params params
     * @dev artist address of artist
     * @dev name name of collection
     * @dev symbol ERC721 symbol for collection
     * @dev script single html as string
     * @dev maxSupply max token supply
     * @dev erc721Index ERC721 implementation index
     * @dev pricingMode minter index
     * @dev pricingData calldata for `setPricing` function
     * @dev payeesMint address list of payees of mint proceeds
     * @dev payeesRoyalties address list of payees of royalties
     * @dev sharesMint list of shares for mint proceeds
     * @dev sharesRoyalties list of shares for royalties
     * Note payee and shares indices must be in respective order
     */
    function createCollection(CreateCollectionParams calldata params)
        external
        onlyAdmin
    {
        address artistAddress = params.artist;
        address minter = minters[params.pricingMode];
        _createArtist(artistAddress);
        address paymentSplitter = GenArtPaymentSplitterFactory(
            paymentSplitterFactory
        ).clone(
                genartAdmin,
                artistAddress,
                params.paymentSplitterIndex,
                params.payeesMint,
                params.payeesRoyalties,
                params.sharesMint,
                params.sharesRoyalties
            );
        address instance = GenArtCollectionFactory(collectionFactory)
            .predictDeterministicAddress(params.erc721Index);
        uint256 price = IGenArtMinter(minter).setPricing(
            instance,
            params.pricingData
        );
        _createCollection(
            CollectionParams(
                artistAddress,
                params.name,
                params.symbol,
                price,
                params.script,
                params.collectionType,
                params.maxSupply,
                params.erc721Index,
                minter,
                paymentSplitter
            )
        );
    }

    /**
     * @dev Internal helper method to create artist
     * @param artist address of artist
     */
    function _createArtist(address artist) internal {
        if (store.getArtist(artist).wallet != address(0)) return;
        address[] memory collections_;
        store.setArtist(Artist(artist, collections_));
    }

    /**
     * @dev Set the {GenArtCollectionFactory} contract address
     */
    function setCollectionFactory(address factory) external onlyAdmin {
        collectionFactory = factory;
    }

    /**
     * @dev Set the {GenArtPaymentSplitterFactory} contract address
     */
    function setPaymentSplitterFactory(address factory) external onlyAdmin {
        paymentSplitterFactory = factory;
    }

    /**
     * @dev Add a minter contract and map by index
     */
    function addMinter(uint8 index, address minter) external onlyAdmin {
        minters[index] = minter;
    }

    /**
     * @dev Get collection info
     * @param collection contract address of the collection
     */
    function getCollectionInfo(address collection)
        external
        view
        returns (CollectionInfo memory info)
    {
        (
            string memory name,
            string memory symbol,
            address artist,
            address minter,
            ,
            ,

        ) = IGenArtERC721(collection).getInfo();
        Artist memory artist_ = store.getArtist(artist);

        info = CollectionInfo(
            name,
            symbol,
            minter,
            store.getCollection(collection),
            artist_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../access/GenArtAccess.sol";
import "../interface/IGenArtMinter.sol";

/**
 * GenArt ERC721 contract factory
 */

struct CollectionParams {
    address artist;
    string name;
    string symbol;
    uint256 price;
    string script;
    uint8 collectionType;
    uint256 maxSupply;
    uint8 erc721Index;
    address minter;
    address paymentSplitter;
}
struct CollectionType {
    string name;
    uint256 prefix;
    uint256 lastId;
}
struct CollectionCreatedEvent {
    uint256 id;
    address contractAddress;
    uint8 collectionType;
    address artist;
    string name;
    string symbol;
    uint256 price;
    string script;
    uint256 maxSupply;
    address minter;
    address implementation;
    address paymentSplitter;
}

contract GenArtCollectionFactory is GenArtAccess {
    mapping(uint8 => address) public erc721Implementations;
    mapping(uint8 => CollectionType) public collectionTypes;
    string public uri;

    event Created(CollectionCreatedEvent collection);

    constructor(string memory uri_) GenArtAccess() {
        uri = uri_;
        collectionTypes[0] = CollectionType("js", 30003, 0);
    }

    /**
     * @dev Get next collection id
     */
    function _getNextCollectionId(uint8 collectioType)
        internal
        returns (uint256)
    {
        CollectionType memory obj = collectionTypes[collectioType];
        uint256 id = obj.prefix + obj.lastId + 1;
        collectionTypes[collectioType].lastId += 1;
        return id;
    }

    /**
     * @dev Create initializer for clone
     * Note The method signature is created on chain to prevent malicious initialization args
     */
    function _createInitializer(
        uint256 id,
        address artist,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address minter,
        address paymentSplitter
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(string,string,string,uint256,uint256,address,address,address,address)",
                name,
                symbol,
                uri,
                id,
                maxSupply,
                genartAdmin,
                artist,
                minter,
                paymentSplitter
            );
    }

    /**
     * @dev Cone an implementation contract
     */
    function cloneCollectionContract(CollectionParams memory params)
        external
        onlyAdmin
        returns (address, uint256)
    {
        address implementation = erc721Implementations[params.erc721Index];
        require(implementation != address(0), "invalid erc721Index");
        uint256 id = _getNextCollectionId(params.collectionType);
        bytes memory initializer = _createInitializer(
            id,
            params.artist,
            params.name,
            params.symbol,
            params.maxSupply,
            params.minter,
            params.paymentSplitter
        );
        address instance = Clones.cloneDeterministic(
            implementation,
            bytes32(block.number)
        );
        Address.functionCall(instance, initializer);
        emit Created(
            CollectionCreatedEvent(
                id,
                instance,
                params.collectionType,
                params.artist,
                params.name,
                params.symbol,
                params.price,
                params.script,
                params.maxSupply,
                params.minter,
                implementation,
                params.paymentSplitter
            )
        );
        return (instance, id);
    }

    /**
     * @dev Add an ERC721 implementation contract and map by index
     */
    function addErc721Implementation(uint8 index, address implementation)
        external
        onlyAdmin
    {
        erc721Implementations[index] = implementation;
    }

    /**
     * @dev Add a collectionType and map by index
     */
    function addCollectionType(
        uint8 index,
        string memory name,
        uint256 prefix,
        uint256 lastId
    ) external onlyAdmin {
        collectionTypes[index] = CollectionType(name, prefix, lastId);
    }

    /**
     * @dev Sets the base tokenURI for collections
     */
    function setUri(string memory uri_) external onlyAdmin {
        uri = uri_;
    }

    /**
     * @dev Predict contract address for new collection
     */
    function predictDeterministicAddress(uint8 erc721Index)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                erc721Implementations[erc721Index],
                bytes32(block.number),
                address(this)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../access/GenArtAccess.sol";

/**
 * GEN.ART {GenArtPaymentSplitter} contract factory
 */

contract GenArtPaymentSplitterFactory is GenArtAccess {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }
    mapping(uint8 => address) public implementations;

    event Created(
        address contractAddress,
        address artist,
        address[] payeesMint,
        address[] payeesRoyalties,
        uint256[] sharesMint,
        uint256[] sharesRoyalties
    );

    constructor(address implementation_) GenArtAccess() {
        implementations[0] = implementation_;
    }

    /**
     * @dev Intenal helper method to create initializer
     */
    function _createInitializer(
        address owner,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address[],address[],uint256[],uint256[])",
                owner,
                payeesMint,
                payeesRoyalties,
                sharesMint,
                sharesRoyalties
            );
    }

    /**
     * @dev Cone a {PaymentSplitter} implementation contract
     */
    function clone(
        address owner,
        address artist,
        uint8 implementation,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) external onlyAdmin returns (address) {
        bytes memory initializer = _createInitializer(
            owner,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        address instance = Clones.clone(implementations[implementation]);
        Address.functionCall(instance, initializer);
        emit Created(
            instance,
            artist,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        return instance;
    }

    /**
     * @dev Set the {GenArtPaymentSplitter} implementation
     */
    function setImplementation(uint8 index, address implementation_)
        external
        onlyAdmin
    {
        implementations[index] = implementation_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";

interface IGenArtERC721 is
    IERC721MetadataUpgradeable,
    IERC2981Upgradeable,
    IERC721EnumerableUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 id,
        uint256 maxSupply,
        address admin,
        address artist,
        address minter,
        address paymentSplitter
    ) external;

    function getTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function getInfo()
        external
        view
        returns (
            string memory,
            string memory,
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function mint(address to, uint256 membershipId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV4 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId)
        external
        view
        returns (address, bool);

    function isVaulted(uint256 _membershipId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtMintAllocator {
    function init(address collection, uint8[3] memory mintAlloc) external;

    function update(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) external;

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);

    function setReservedGold(address collection, uint8 reservedGold) external;

    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtMinter {
    function mintOne(address collection, uint256 membershipId) external payable;

    function mint(address collection, uint256 amount) external payable;

    function getPrice(address collection) external view returns (uint256);

    function setPricing(address collection, bytes memory data)
        external
        returns (uint256);

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);

    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitterV5 {
    function splitPayment(uint256 mintValue) external payable;

    function getTotalShares(uint8 _payment) external view returns (uint256);

    function release(address account) external;

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../interface/IGenArtMinter.sol";
import "../interface/IGenArtMintAllocator.sol";

/**
 * @dev GEN.ART Default Minter
 * Admin for collections deployed on {GenArtCurated}
 */

abstract contract GenArtMinterBase is GenArtAccess, IGenArtMinter {
    struct MintParams {
        uint256 startTime;
        address mintAllocContract;
    }
    address public genArtCurated;
    address public genartInterface;
    mapping(address => MintParams) public mintParams;

    constructor(address genartInterface_, address genartCurated_)
        GenArtAccess()
    {
        genartInterface = genartInterface_;
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function _setMintParams(
        address collection,
        uint256 startTime,
        address mintAllocContract
    ) internal {
        require(
            mintParams[collection].startTime == 0,
            "pricing already exists for collection"
        );
        require(
            mintParams[collection].startTime < block.timestamp,
            "mint already started for collection"
        );
        require(startTime > block.timestamp, "startTime too early");

        mintParams[collection] = MintParams(startTime, mintAllocContract);
    }

    /**
     * @dev Set the {GenArtInferface} contract address
     */
    function setInterface(address genartInterface_) external onlyAdmin {
        genartInterface = genartInterface_;
    }

    /**
     * @dev Set the {GenArtCurated} contract address
     */
    function setCurated(address genartCurated_) external onlyAdmin {
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Get all available mints for account
     * @param collection contract address of the collection
     * @param account address of account
     */
    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getAvailableMintsForAccount(collection, account);
    }

    /**
     * @dev Get available mints for a GEN.ART membership
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view virtual override returns (uint256) {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getAvailableMintsForMembership(collection, membershipId);
    }

    /**
     * @dev Get amount of minted tokens for a GEN.ART membership
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getMembershipMints(collection, membershipId);
    }

    /**
     * @dev Get collection {MintParams} object
     * @param collection contract address of the collection
     */
    function getMintParams(address collection)
        external
        view
        returns (MintParams memory)
    {
        return mintParams[collection];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "./GenArtMinterBase.sol";

/**
 * @dev GEN.ART Minter Flash loan
 * Admin for collections deployed on {GenArtCurated}
 */

struct FlashLoanParams {
    uint256 startTime;
    uint256 price;
    address mintAllocContract;
}

contract GenArtMinterFlash is GenArtMinterBase {
    uint256 DOMINATOR = 1000;
    address public payoutAddress;
    address public loyaltyPool;
    address public membershipLendingPool;
    uint256 public lendingFeePercentage = 0;
    uint256 public loyaltyRewardBps = 125;

    mapping(address => uint256[]) public pooledMemberships;
    mapping(address => uint256) public prices;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address membershipLendingPool_,
        address payoutAddress_,
        address loyaltyPool_
    ) GenArtMinterBase(genartInterface_, genartCurated_) {
        membershipLendingPool = membershipLendingPool_;
        payoutAddress = payoutAddress_;
        loyaltyPool = loyaltyPool_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded data
     */
    function setPricing(address collection, bytes memory data)
        external
        override
        onlyAdmin
        returns (uint256)
    {
        FlashLoanParams memory params = abi.decode(data, (FlashLoanParams));
        _setPricing(
            collection,
            params.startTime,
            params.price,
            params.mintAllocContract
        );
        return params.price;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract
    ) external onlyAdmin {
        _setPricing(collection, startTime, price, mintAllocContract);
    }

    /**
     * @dev Internal helper method to set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function _setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract
    ) internal {
        super._setMintParams(collection, startTime, mintAllocContract);
        prices[collection] = price;
        pooledMemberships[collection] = IGenArtInterfaceV4(genartInterface)
            .getMembershipsOf(membershipLendingPool);
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (prices[collection] * (1000 + lendingFeePercentage)) / 1000;
    }

    /**
     * @dev Get available pooled memberships
     * @param collection contract address of the collection
     */
    function getPooledMemberships(address collection)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return pooledMemberships[collection];
    }

    /**
     * @dev Get available pooled memberships
     * @param collection contract address of the collection
     */
    function getTotalPooledMemberships(address collection)
        public
        view
        virtual
        returns (uint256)
    {
        return pooledMemberships[collection].length;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection) internal view {
        require(msg.value == getPrice(collection), "wrong amount sent");
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            collection
        ).getInfo();
        require(totalSupply + 1 <= maxSupply, "collection sold out");
        require(
            pooledMemberships[collection].length > 0,
            "no memberships available"
        );
        require(
            mintParams[collection].startTime != 0,
            "falsh loan mint not started yet"
        );
        require(
            mintParams[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param "" any uint256
     */
    function mintOne(address collection, uint256) external payable override {
        _checkMint(collection);
        uint256 membershipId = pooledMemberships[collection][
            pooledMemberships[collection].length - 1
        ];
        pooledMemberships[collection].pop();
        _mint(collection, membershipId);
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to mint tokens on {IGenArtERC721} contracts
     */
    function _mint(address collection, uint256 membershipId) internal {
        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(msg.sender, membershipId);
    }

    /**
     * @dev Only one token possible to mint
     * Note DO NOT USE
     */
    function mint(address, uint256) external payable override {
        revert("not implemented");
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        uint256 value = msg.value;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);
        uint256 amount = (value / (DOMINATOR + lendingFeePercentage)) *
            DOMINATOR;
        uint256 loyalties = (amount * loyaltyRewardBps) / DOMINATOR;
        payable(loyaltyPool).transfer(loyalties);
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{
            value: amount - loyalties
        }(amount);
    }

    /**
     * @dev Set the flash lending fee
     */
    function setMembershipLendingFee(uint256 lendingFeePercentage_)
        external
        onlyAdmin
    {
        lendingFeePercentage = lendingFeePercentage_;
    }

    /**
     * @dev Set membership pool address
     */
    function setMembershipLendingPool(address membershipLendingPool_)
        external
        onlyAdmin
    {
        membershipLendingPool = membershipLendingPool_;
    }

    /**
     * @dev Set membership pool address
     */
    function removeMembership(address collection, uint256 membershipIndex)
        external
        onlyAdmin
    {
        pooledMemberships[collection][membershipIndex] = pooledMemberships[
            collection
        ][pooledMemberships[collection].length - 1];
        pooledMemberships[collection].pop();
    }

    /**
     * @dev Set the loyalty reward bps per mint {e.g 125}
     */
    function setLoyaltyRewardBps(uint256 bps) external onlyAdmin {
        loyaltyRewardBps = bps;
    }

    /**
     * @dev Set the payout address for the flash lending fees
     */
    function setPayoutAddress(address payoutAddress_) external onlyGenArtAdmin {
        payoutAddress = payoutAddress_;
    }

    /**
     * @dev Set the payout address for the flash lending fees
     */
    function setLoyaltyPool(address loyaltyPool_) external onlyAdmin {
        loyaltyPool = loyaltyPool_;
    }

    /**
     * @dev Widthdraw contract balance
     */
    function withdraw() external onlyAdmin {
        payable(payoutAddress).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";

struct Collection {
    uint256 id;
    address artist;
    address contractAddress;
    uint256 maxSupply;
    string script;
    address paymentSplitter;
}

struct Artist {
    address wallet;
    address[] collections;
}

contract GenArtStorage is GenArtAccess {
    mapping(address => Collection) public collections;
    mapping(address => Artist) public artists;

    event ScriptUpdated(address collection, string script);

    /**
     * @dev Helper function to get {PaymentSplitter} of artist
     */
    function getPaymentSplitterForCollection(address collection)
        external
        view
        returns (address)
    {
        return collections[collection].paymentSplitter;
    }

    /**
     * @dev Update script of collection
     * @param collection contract address of the collection
     * @param script single html as string
     */
    function updateScript(address collection, string memory script) external {
        address sender = _msgSender();
        require(
            collections[collection].artist == sender ||
                admins[sender] ||
                owner() == sender,
            "not allowed"
        );
        collections[collection].script = script;
        emit ScriptUpdated(collection, script);
    }

    /**
     * @dev set collection
     * @param collection contract object
     */
    function setCollection(Collection calldata collection) external onlyAdmin {
        collections[collection.contractAddress] = collection;
        artists[collection.artist].collections.push(collection.contractAddress);
    }

    /**
     * @dev set collection
     * @param artist artist object
     */
    function setArtist(Artist calldata artist) external onlyAdmin {
        artists[artist.wallet] = artist;
    }

    /**
     * @dev Get artist struct
     * @param artist adress of artist
     */
    function getArtist(address artist) external view returns (Artist memory) {
        return artists[artist];
    }

    /**
     * @dev Get collection struct
     * @param collection collection address
     */
    function getCollection(address collection)
        external
        view
        returns (Collection memory)
    {
        return collections[collection];
    }

    /**
     * @dev Update payment splitter for collection
     * @param paymentSplitter address of new payment splitter
     */
    function setPaymentSplitter(address collection, address paymentSplitter)
        external
        onlyAdmin
    {
        collections[collection].paymentSplitter = paymentSplitter;
    }
}