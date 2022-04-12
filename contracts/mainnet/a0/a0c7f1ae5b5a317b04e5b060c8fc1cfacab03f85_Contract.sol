/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// File: IWhitelist.sol


// Creator: OZ

pragma solidity ^0.8.4;

interface IWhitelist {
    function check(address addr) external view returns(bool);
}

// File: Errors.sol


// Creator: OZ using Chiru Labs

pragma solidity ^0.8.4;

error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error AssetCannotBeTransfered();
error AssetLocked();
error AssetNotLocked();
error BalanceQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error CallerNotOwnerNorApproved();
error Err();
error LackOfMoney();
error LockCallerNotOwnerNorApproved();
error MintShouldBeOpened();
error MintToZeroAddress();
error MintZeroQuantity();
error MintedQueryForZeroAddress();
error OutOfMintBoundaries();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error RootAddressError();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();
error WhitelistedOnly();

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: Strings.sol


pragma solidity ^0.8.4;

/**
 * Libraries
 * Used https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol for Strings
 */

library Strings{

    bytes16 private constant _HEXSYMBOLS = "0123456789abcdef";

    function toString(address account) public pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes32 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toString(uint256 value) internal pure returns(string memory)
    {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (0 == value) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (0 != temp) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (0 != value) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns(string memory)
    {
        if (0 == value) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (0 != temp) {
            length++;
            temp >>= 8;
        }
        return toHexString(value,length);
    }

    function toHexString(uint256 value,uint256 length) internal pure returns(string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEXSYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0);
        return string(buffer);
    }
    
    function concat(string memory self, string memory other) internal pure returns(string memory)
    {
        return string(
        abi.encodePacked(
            self,
            other
        ));
    }
    
}

// File: TokenStorage.sol


// Creator: OZ

pragma solidity ^0.8.4;

contract TokenStorage {

    enum MintStatus {
        NONE,
        PRESALE,
        SALE
    }

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        uint64 numberMintedOnPresale;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    struct ContractData {
        // Token name
        string name;
        // Token description
        string description;
        // Token symbol
        string symbol;
        // Base URL for tokens metadata
        string baseURL;
        // Contract-level metadata URL
        string contractURL;
        // Whitelist Merkle tree root
        bytes32 wl;
        // Is it set or asset?
        bool isEnvelope;
        // Revealed?
        bool isRevealed;
        // Mint status managed by
        bool mintStatusAuto;
        // Status
        MintStatus mintStatus;
    }

    struct EnvelopeTypes {
        address envelope;
        address[] types;
    }

    struct MintSettings {
        uint8 mintOnPresale;
        uint8 maxMintPerUser;
        uint8 minMintPerUser;
        uint64 maxTokenSupply;
        uint256 priceOnPresale;
        uint256 priceOnSale;
        uint256 envelopeConcatPrice;
        uint256 envelopeSplitPrice;
        // MintStatus timing
        uint256 mintStatusPreale;
        uint256 mintStatusSale;
        uint256 mintStatusFinished;
    }

    // Contract root address
    address internal _root;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Contract data
    ContractData internal _contractData;

    // Envelope data
    EnvelopeTypes internal _envelopeTypes;

    // Mint settings
    MintSettings internal _mintSettings;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping owner address to address data
    mapping(address => AddressData) internal _addressData;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Envelope container
    mapping(uint256 => mapping(address => uint256)) internal _assetsEnvelope;
    mapping(address => mapping(uint256 => bool)) internal _assetsEnveloped;

}
// File: IEnvelope.sol


// Creator: OZ

pragma solidity ^0.8.4;

interface IEnvelope {
    function locked(address _asset,uint256 _assetId) external view returns(bool);
    function ownerOfAsset(uint256 _assetId) external view returns(address);
    }

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: Ownership.sol


// Creator: OZ using Chiru Labs

pragma solidity ^0.8.4;





contract Ownership is Context, TokenStorage {

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId)
    internal view
    returns (TokenOwnership memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    uint256[] private __tokens__;

    function tokensOf(address _owner)
    external
    returns(uint256[] memory tokens)
    {
        unchecked {
            for(uint i=0;i<_currentIndex;i++) {
                TokenOwnership memory ownership = ownershipOf(i);
                if(ownership.addr == _owner) {
                    if (!ownership.burned) {
                        if(_contractData.isEnvelope) {
                            __tokens__.push(i);
                        } else {
                            if(!IEnvelope(_envelopeTypes.envelope).locked(address(this),i)) {
                                __tokens__.push(i);
                            }
                        }
                    }
                }
            }
            return __tokens__;
        }
    }

}
// File: AccessControl.sol


// Creator: OZ

pragma solidity ^0.8.4;




contract AccessControl is Ownership {

    function ActiveMint()
    internal view
    {
        if(MintStatus.NONE == _contractData.mintStatus)
            revert MintShouldBeOpened();
    }

    function ApprovedOnly(address owner)
    internal view
    {
        if (!_operatorApprovals[owner][_msgSender()])
            revert CallerNotOwnerNorApproved();
    }

    function BotProtection()
    internal view
    {
        if(tx.origin != msg.sender)
            revert Err();
    }

    function OwnerOnly(address owner,uint256 tokenId)
    internal view
    {
        if (owner != ownershipOf(tokenId).addr)
            revert CallerNotOwnerNorApproved();
    }

    function RootOnly()
    internal view
    {
        address sender = _msgSender();
        if(
            sender != _root &&
            sender != _envelopeTypes.envelope
        ) revert RootAddressError();
    }

    function Whitelisted(bytes32[] calldata _merkleProof)
    internal view
    {
        address sender = _msgSender();
        bool flag =
            _root == sender ||
            _contractData.mintStatus == MintStatus.SALE
        ;

        /**
         * Set merkle tree root
         */
        if(!flag)
            flag = MerkleProof.verify(_merkleProof, _contractData.wl, keccak256(abi.encodePacked(sender)));

        /**/
        if(!flag)
            revert WhitelistedOnly();
    }

    function setWLRoot(bytes32 _root)
    external
    {
        RootOnly();

        _contractData.wl = _root;
    }

}
// File: Array.sol


// Creator: OZ

pragma solidity ^0.8.4;

contract Array{

    function remove(uint256[] memory arr, uint256 e)
    internal pure
    {
        unchecked {
            uint idx = 0;
            for(uint i = 0; i < arr.length; i++) {
                if(arr[i] == e) {
                    idx = i;
                }
            }
            for (uint i = idx; i < arr.length-1; i++){
                arr[i] = arr[i+1];        
            }
            delete arr[arr.length - 1];
        }
    }
    
}
// File: Math.sol


pragma solidity ^0.8.4;

library Math{

    function max(uint256 a,uint256 b) internal pure returns(uint256)
    {
        return a >= b ? a : b;
    }

    function min(uint256 a,uint256 b) internal pure returns(uint256)
    {
        return a < b ? a : b;
    }

    function average(uint256 a,uint256 b) internal pure returns(uint256)
    {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a,uint256 b) internal pure returns(uint256)
    {
        return a / b + (a % b == 0 ? 0 : 1);
    }

    function mul(uint256 a,uint256 b) internal pure returns(uint256 c)
    {
        if (0 == a) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a,uint256 b) internal pure returns(uint256)
    {
        assert(0 != b);
        return a / b;
    }

    function sub(uint256 a,uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a,uint256 b) internal pure returns(uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: Payment.sol


// Creator: OZ

pragma solidity ^0.8.4;



contract Payment is TokenStorage {

    function lackOfMoney(uint _quantity)
    internal
    returns(bool)
    {
        return msg.value < Math.mul(_contractData.mintStatus == MintStatus.PRESALE ?
        _mintSettings.priceOnPresale : _mintSettings.priceOnSale
        ,_quantity);
    }

    function lackOfMoneyForConcat()
    internal
    returns(bool)
    {
        return
            _mintSettings.envelopeConcatPrice != 0 &&
            _mintSettings.envelopeConcatPrice > msg.value
            ;
    }

    function lackOfMoneyForSplit()
    internal
    returns(bool)
    {
        return
            _mintSettings.envelopeSplitPrice != 0 &&
            _mintSettings.envelopeSplitPrice > msg.value
            ;
    }

}
// File: Quantity.sol


// Creator: OZ

pragma solidity ^0.8.4;



contract Quantity is TokenStorage {

    function quantityIsGood(uint256 _quantity,uint256 _minted,uint256 _mintedOnPresale)
    internal view
    returns(bool)
    {
        return
            (
                _contractData.mintStatus == MintStatus.PRESALE &&
                _mintSettings.mintOnPresale >= _quantity + _minted
            ) || (
                _contractData.mintStatus == MintStatus.SALE &&
                _mintSettings.maxMintPerUser >= _quantity + _minted - _mintedOnPresale &&
                _mintSettings.minMintPerUser <= _quantity
            )
            ;
    }

    function supplyIsGood()
    internal view
    returns(bool)
    {
        return
            _contractData.isEnvelope || (
                _contractData.isEnvelope == false &&
                _mintSettings.maxTokenSupply > _currentIndex
            )
            ;
    }

}
// File: ERC721A.sol


// Creator: Chiru Labs

pragma solidity ^0.8.4;












//import "hardhat/console.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
abstract contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, AccessControl, Quantity {
    using Address for address;
    using Strings for uint256;

    constructor(
        string memory name_,
        string memory description_,
        string memory symbol_,
        string memory baseURL_,
        string memory contractURL_
    ) {
        _contractData.name = name_;
        _contractData.description = description_;
        _contractData.symbol = symbol_;
        _contractData.baseURL = baseURL_;
        _contractData.contractURL = contractURL_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply()
    public view
    returns(uint256)
    {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public view virtual
    override(ERC165, IERC165)
    returns(bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
    public view
    override
    returns(uint256)
    {
        if (owner == address(0))
            revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * returnsthe number of tokens minted by `owner`.
     */
    function _numberMinted(address owner)
    internal view
    returns(uint256)
    {
        if (owner == address(0))
            revert MintedQueryForZeroAddress();
        else return
            uint256(_addressData[owner].numberMinted);
    }

    function _numberMintedOnPresale(address owner)
    internal view
    returns(uint256)
    {
        if (owner == address(0))
            revert MintedQueryForZeroAddress();
        else return
            uint256(_addressData[owner].numberMintedOnPresale);
    }

    /**
     * returnsthe number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner)
    internal view
    returns(uint256)
    {
        if (owner == address(0))
            revert BurnedQueryForZeroAddress();
        else return
            uint256(_addressData[owner].numberBurned);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
    public view
    override
    returns(address)
    {
        if(!_contractData.isEnvelope) {
            if(IEnvelope(_envelopeTypes.envelope).locked(address(this),tokenId)) {
                return address(0);
            }
        }
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId)
    public
    override
    {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner)
            revert ApprovalToCurrentOwner();
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert CallerNotOwnerNorApproved();
        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
    public view
    override
    returns(address)
    {
        if (!_exists(tokenId))
            revert ApprovalQueryForNonexistentToken();
        else return
            _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
    public
    override
    {
        if (operator == _msgSender())
            revert ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public view virtual
    override
    returns(bool)
    {
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
        if(!_contractData.isEnvelope)
            if(IEnvelope(_envelopeTypes.envelope).locked(address(this),tokenId))
                revert AssetLocked();
                
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
        safeTransferFrom(from, to, tokenId, '');
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
        if(!_contractData.isEnvelope)
            if(IEnvelope(_envelopeTypes.envelope).locked(address(this),tokenId))
                revert AssetLocked();

        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev returnswhether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId)
    internal view
    returns(bool)
    {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if(!supplyIsGood())
            revert OutOfMintBoundaries();
        if (to == address(0))
            revert MintToZeroAddress();
        if (quantity == 0)
            revert MintZeroQuantity();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);
            if(_contractData.mintStatus == MintStatus.PRESALE)
                _addressData[to].numberMintedOnPresale = _addressData[to].numberMintedOnPresale + uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data))
                    revert TransferToNonERC721ReceiverImplementer();
                updatedIndex++;
            }

            _currentIndex = updatedIndex;
        }
    }

    /**
     * Transfer set and all its assets
     */
    function _transferEnvelope(address _to,uint256 _assetId)
    internal
    {
        unchecked {
            for (uint i = 0; i < _envelopeTypes.types.length; i++) {
                (bool success,bytes memory res) = _envelopeTypes.types[i].call(
                    abi.encodeWithSignature("unlock(uint256,address)",
                        _assetsEnvelope[_assetId][_envelopeTypes.types[i]],
                        _to)
                );
                if(!success)
                    revert AssetCannotBeTransfered();
            }
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) internal {

        TokenOwnership memory prevOwnership = ownershipOf(tokenId);
        address sender = _msgSender();

        bool isApprovedOrOwner = (
            sender == _envelopeTypes.envelope ||
            sender == prevOwnership.addr ||
            sender == getApproved(tokenId) ||
            isApprovedForAll(prevOwnership.addr, sender)
        );

        if (!isApprovedOrOwner)
            revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from)
            revert TransferFromIncorrectOwner();
        if (to == address(0))
            revert TransferToZeroAddress();

        /*
        if(
            sender == prevOwnership.addr &&
            _contractData.isEnvelope
        ) _transferEnvelope(to,tokenId);
        */

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
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
    function _burn(uint256 tokenId)
    internal virtual
    {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
    ) private returns(bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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

    function getBalance()
    external view
    returns(uint256)
    {
        if(_root != _msgSender())
            revert RootAddressError();
        return address(this).balance;
    }

    function withdraw(address _to,uint256 _amount)
    external
    {
        if(_root != _msgSender())
            revert RootAddressError();
        if(address(this).balance < _amount)
            revert LackOfMoney();
        payable(_to).transfer(_amount);
    }

}

// File: ERC721AToken.sol


// Creator: Chiru Labs & OZ

pragma solidity ^0.8.4;




/**
 * @title ERC721A Base Token
 * @dev ERC721A Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721AToken is Context, Ownership, ERC721A {
    using Strings for uint256;

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name()
    external view virtual
    override
    returns(string memory)
    {
        return _contractData.name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol()
    external view virtual
    override
    returns(string memory)
    {
        return _contractData.symbol;
    }

    function baseTokenURI()
    external view
    returns(string memory)
    {
        return _contractData.baseURL;
    }
  
    function contractURI()
    external view
    returns(string memory)
    {
        return _contractData.contractURL;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    external view
    override
    returns(string memory)
    {
        if (!_exists(tokenId))
            revert URIQueryForNonexistentToken();

        return string(
                abi.encodePacked(
                    _contractData.baseURL,
                    "/",
                    Strings.toString(tokenId),
                    ".json"
                ));
    }

    function decimals()
    external pure
    returns(uint8)
    {
        return 0;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId)
    internal
    {
        if(!_contractData.isEnvelope)
            if(IEnvelope(_envelopeTypes.envelope).locked(address(this),tokenId))
                revert AssetLocked();
                
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner)
            revert TransferCallerNotOwnerNorApproved();

        _burn(tokenId);
    }

}
// File: IAsset.sol


// Creator: OZ

pragma solidity ^0.8.4;

interface IAsset {
    function checkMint(address _owner,uint256 _quantity) external returns(uint256);
    function locked(uint256 _assetId) external view returns(bool);
    function ownerOfAsset(uint256 _assetId) external view returns(address);
    }

// File: ERC721AEnvelope.sol


// Creator: OZ

pragma solidity ^0.8.4;





//import "hardhat/console.sol";

abstract contract ERC721AEnvelope is Array, Context, ERC721AToken {
    using Math for uint256;

    function _mintSetOfAssets(address _owner,uint _quantity)
    internal
    {
        unchecked {
            for(uint i = 0; i < _envelopeTypes.types.length; i++) {
                (bool success,bytes memory res) = _envelopeTypes.types[i].call(
                    abi.encodeWithSignature("safeMint(address,uint256)",
                        _owner,
                        _quantity
                        )
                );
                if(!success)
                    revert Err();
            }
        }
    }

    function _envelopeAssets(uint256 _envelopeId)
    internal view
    returns(address[] memory,uint256[] memory)
    {
        unchecked {
            uint len = 0;
            for (uint i = 0; i < _envelopeTypes.types.length; i++) {
                len++;
            }
            address[] memory addrs = new address[](len);
            uint256[] memory tokens = new uint256[](len);
            len = 0;
            for (uint i = 0; i < _envelopeTypes.types.length; i++) {
                addrs[len] = _envelopeTypes.types[i];
                tokens[len++] = _assetsEnvelope[_envelopeId][_envelopeTypes.types[i]];
            }
            return (addrs,tokens);
        }
    }

    function _envelopeSplit(address _owner,uint256 _envelopeId)
    internal
    returns(address[] memory,uint256[] memory)
    {
        OwnerOnly(_owner,_envelopeId);

        (address[] memory addrs,uint256[] memory tokens) = _envelopeAssets(_envelopeId);
        _burn(_envelopeId);
        _transferEnvelope(_owner,_envelopeId);
        unchecked {
            for(uint i = 0; i < addrs.length; i++) {
                _unlockEnvelopeAsset(
                        _envelopeId,
                        addrs[i],
                        tokens[i]
                        );
            }
        }
        return (addrs,tokens);
    }

    function _unlockEnvelopeAsset(uint256 _envelopeId,address _asset,uint256 _assetId)
    internal
    {
        if(!_locked(_asset,_assetId))
            revert AssetNotLocked();
        if(_msgSender() != IAsset(_asset).ownerOfAsset(_assetId))
            revert CallerNotOwnerNorApproved();

        delete _assetsEnveloped[_asset][_assetId];
        delete _assetsEnvelope[_envelopeId][_asset];
    }

    function _envelopeCreate(address _owner,address[] calldata _assets,uint256[] calldata _assetIds)
    internal
    returns(uint256)
    {
        if(
            _assets.length == 0 &&
            _assets.length != _assetIds.length
        ) revert Err();

        uint256 envelopeId = _currentIndex;
        _safeMint(_owner,1);
        unchecked {
            _assetsEnvelope[envelopeId][_envelopeTypes.envelope] = envelopeId;
            for(uint i = 0; i < _assets.length; i++) {
                if(_locked(_assets[i],_assetIds[i]))
                    revert AssetLocked();
                if(_owner != IAsset(_assets[i]).ownerOfAsset(_assetIds[i]))
                    revert CallerNotOwnerNorApproved();
                _assetsEnvelope[envelopeId][_assets[i]] = _assetIds[i];
                _assetsEnveloped[_assets[i]][_assetIds[i]] = true;
            }
        }
        return envelopeId;
    }

    function _locked(address _asset,uint256 _assetId)
    internal view
    returns(bool)
    {
        if (_contractData.isEnvelope)
            return _assetsEnveloped[_asset][_assetId];
        else
            return IAsset(_envelopeTypes.envelope).locked(_assetId);
    }

}

// File: Master.sol


// Creator: OZ

pragma solidity ^0.8.4;


abstract contract Master is ERC721AEnvelope {

    constructor() {
        _root = _msgSender();
        _contractData.isRevealed = false;
        _contractData.mintStatus = MintStatus.NONE;
        _contractData.mintStatusAuto = true;
        _mintSettings.mintOnPresale = 1; // number of tokens on presale
        _mintSettings.maxMintPerUser = 2; // max tokens on sale
        _mintSettings.minMintPerUser = 1; // min tokens on sale
        _mintSettings.maxTokenSupply = 5000;
        _mintSettings.priceOnPresale = 37500000000000000; // in wei, may be changed later
        _mintSettings.priceOnSale = 47500000000000000; // in wei, may be changed later
        _mintSettings.envelopeConcatPrice = 0; // in wei, may be changed later
        _mintSettings.envelopeSplitPrice = 0; // in wei, may be changed later
        _mintSettings.mintStatusPreale = 1649683800; // Monday, April 11, 2022 2:00:00 PM GMT
        _mintSettings.mintStatusSale = 1649734200; // Tuesday, April 12, 2022 3:30:00 AM
        _mintSettings.mintStatusFinished = 0; //does not specified
    }

    function exists(uint256 tokenId)
    external view
    returns(bool)
    {
        return _exists(tokenId);
    }

    function setRoot(address _owner)
    external
    {
        RootOnly();
        
        _root = _owner;
    }

    function getRoot()
    external view
    returns(address)
    {
        return _root;
    }

    function CheckMintStatus()
    internal
    {
        if(!_contractData.mintStatusAuto)
            return;
        
        uint256 mps = _mintSettings.mintStatusPreale;
        uint256 ms = _mintSettings.mintStatusSale;
        uint256 mf = _mintSettings.mintStatusFinished;
        if (mps <= block.timestamp && block.timestamp < ms) {
            _contractData.mintStatus = MintStatus.PRESALE;
        } else if (ms <= block.timestamp && (block.timestamp < mf || 0 == mf)) {
            _contractData.mintStatus = MintStatus.SALE;
        } else {
            _contractData.mintStatus = MintStatus.NONE;
        }
    }

    function toggleMintStatus(bool _mode)
    external
    {
        RootOnly();

        _contractData.mintStatusAuto = _mode;
    }

    function setMintingIsOnPresale()
    external
    {
        RootOnly();

        _contractData.mintStatus = MintStatus.PRESALE;
    }
    
    function setMintingIsOnSale()
    external
    {
        RootOnly();

        _contractData.mintStatus = MintStatus.SALE;
    }
     
    function stopMinting()
    external
    {
        RootOnly();

        _contractData.mintStatus = MintStatus.NONE;
    }

    function updateContract(
        uint256 _pricePresale,
        uint256 _priceSale,
        uint8 _minMint,
        uint8 _maxMint,
        uint64 _maxSupply
        )
    external
    {
        RootOnly();

        _mintSettings.priceOnPresale = _pricePresale;
        _mintSettings.priceOnSale = _priceSale;
        _mintSettings.maxMintPerUser = _maxMint;
        _mintSettings.minMintPerUser = _minMint;
        _mintSettings.maxTokenSupply = _maxSupply;
    }

    function setRevealed(string calldata _url)
    external
    {
        RootOnly();

        _contractData.isRevealed = true;
        _contractData.baseURL = _url;
    }

    function updateBaseURL(string calldata _url)
    external
    {
        RootOnly();

        _contractData.baseURL = _url;
    }

}
// File: Contract.sol


// Creator: OZ

pragma solidity ^0.8.4;




contract Contract is Master, Payment, IEnvelope {

    constructor(
        string memory name_,
        string memory description_,
        string memory symbol_,
        string memory baseURL_,
        string memory contractURL_
    ) ERC721A(
        name_,
        description_,
        symbol_,
        baseURL_,
        contractURL_
    ) Master() {
        _contractData.isEnvelope = true;
        //_contractData.wl = 0x7355b511eb06aa6d5a11b366b27ed407bc3237cf6e2eafe1799efef4a678756f;
        _contractData.wl = 0xcdab47e163c1eb6040f36523ce1ddb86b732c6e652e159613a6e0b896d4f8232;
    }

    function addAssetType(address _asset)
    external
    {
        RootOnly();

        unchecked {
            _envelopeTypes.types.push(_asset);
        }
    }

    function setEnvelopeConcatPrice(uint256 _price)
    external
    {
        RootOnly();

        _mintSettings.envelopeConcatPrice = _price;
    }

    function setEnvelopeSplitPrice(uint256 _price)
    external
    {
        RootOnly();

        _mintSettings.envelopeSplitPrice = _price;
    }

    function addMint(uint _quantity)
    external payable
    returns(uint256)
    {
        BotProtection();
        CheckMintStatus();
        ActiveMint();

        if(_contractData.mintStatus != MintStatus.SALE)
            revert WhitelistedOnly();

        //
        if (lackOfMoney(_quantity * _envelopeTypes.types.length))
            revert LackOfMoney();
        else {
            _mintSetOfAssets(_msgSender(), _quantity);
            return _quantity;
        }
    }

    function addMint(uint _quantity,bytes32[] calldata _merkleProof)
    external payable
    returns(uint256)
    {
        BotProtection();
        CheckMintStatus();
        ActiveMint();
        Whitelisted(_merkleProof);

        if (lackOfMoney(_quantity * _envelopeTypes.types.length))
            revert LackOfMoney();
        else {
            _mintSetOfAssets(_msgSender(), _quantity);
            return _quantity;
        }
    }

    function addMint(address _owner,uint _quantity)
    external
    {
        RootOnly();
        CheckMintStatus();

        _mintSetOfAssets(_owner, _quantity);
    }

    function envelopeCreate(address[] calldata _assets,uint256[] calldata _assetIds)
    external payable 
    returns(uint256)
    {
        if(lackOfMoneyForConcat())
            revert LackOfMoney();
        else return
            _envelopeCreate(_msgSender(),_assets, _assetIds);
    }

    function envelopeSplit(uint256 _envelopeId)
    external payable
    returns(address[] memory,uint256[] memory)
    {
        OwnerOnly(_msgSender(),_envelopeId);

        if(lackOfMoneyForSplit())
            revert LackOfMoney();
        else return
            _envelopeSplit(_msgSender(),_envelopeId);
    }

    function getAssetTypes()
    external view
    returns(address[] memory)
    {
        return _envelopeTypes.types;
    }

    function getEnvelopeAssets(uint256 _envelopeId)
    external view
    returns(address[] memory,uint256[] memory)
    {
        return _envelopeAssets(_envelopeId);
    }

    function locked(address _asset,uint256 _assetId)
    external view
    override
    returns(bool)
    {
        return _assetsEnveloped[_asset][_assetId];
    }

    function ownerOfAsset(uint256 _assetId)
    external view
    override
    returns(address)
    {
        return ownershipOf(_assetId).addr;
    }

}