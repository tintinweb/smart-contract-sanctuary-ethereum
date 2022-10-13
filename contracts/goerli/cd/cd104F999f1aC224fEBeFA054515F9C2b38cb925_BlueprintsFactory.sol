/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

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
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}
/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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
    uint256[49] private __gap;
}

abstract contract HasSecondarySaleFees is ERC165StorageUpgradeable {
    event SecondarySaleFees(
        uint256 tokenId,
        address[] recipients,
        uint256[] bps
    );

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    function _initialize() public initializer {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function getFeeRecipients(uint256 id)
        public
        view
        virtual
        returns (address[] memory);

    function getFeeBps(uint256 id)
        public
        view
        virtual
        returns (uint32[] memory);
}

/**
 * @dev Interface used to share common types between AsyncArt Blueprints contracts
 * @author Ohimire Labs
 */
interface IBlueprintTypes {
    /**
     * @dev Core administrative accounts 
     * @param platform Platform, holder of DEFAULT_ADMIN role
     * @param minter Minter, holder of MINTER_ROLE
     * @param asyncSaleFeesRecipient Recipient of primary sale fees going to platform
     */
    struct Admins {
        address platform;
        address minter;
        address asyncSaleFeesRecipient;
    } 

    /**
     * @dev Object passed in when preparing blueprint 
     * @param _capacity Number of NFTs in Blueprint 
     * @param _price Price per NFT in Blueprint
     * @param _erc20Token Address of ERC20 currency required to buy NFTs, can be zero address if expected currency is native gas token 
     * @param _blueprintMetaData Blueprint metadata uri
     * @param _baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param _merkleroot Root of Merkle tree holding whitelisted accounts 
     * @param _mintAmountArtist Amount of NFTs of Blueprint mintable by artist
     * @param _mintAmountPlatform Amount of NFTs of Blueprint mintable by platform 
     * @param _maxPurchaseAmount Max number of NFTs purchasable in a single transaction
     * @param _saleEndTimestamp Timestamp when the sale ends 
     */ 
    struct BlueprintPreparationConfig {
        uint64 _capacity;
        uint128 _price;
        address _erc20Token;
        string _blueprintMetaData;
        string _baseTokenUri;
        bytes32 _merkleroot;
        uint32 _mintAmountArtist;
        uint32 _mintAmountPlatform;
        uint64 _maxPurchaseAmount;
        uint128 _saleEndTimestamp;
    }

    /**
     * @dev Object holding primary fee data
     * @param primaryFeeBPS Primary fee percentage allocations, in basis points
     * @param primaryFeeRecipients Primary fee recipients 
     */
    struct PrimaryFees {
        uint32[] primaryFeeBPS;
        address[] primaryFeeRecipients;
    }
}
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
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
}
/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}
/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}
/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)
/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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

/**
 * @dev Async Art Blueprint NFT contract with true creator provenance
 * @author Async Art, Ohimire Labs 
 */
contract CreatorBlueprints is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuard
{
    using StringsUpgradeable for uint256;

    /**
     * @dev Default fee given to platform on primary sales
     */
    uint32 public defaultPlatformPrimaryFeePercentage;    

    /**
     * @dev Token id of last ERC721 NFT minted
     */ 
    uint64 public latestErc721TokenIndex;

    /**
     * @dev Platform account receiving fees from primary sales
     */
    address public asyncSaleFeesRecipient;

    /**
     * @dev Account representing platform 
     */
    address public platform;

    /**
     * @dev Account able to perform actions restricted to MINTER_ROLE holder
     */
    address public minterAddress;

    /**
     * @dev Blueprint artist 
     */
    address public artist;
    
    /**
     * @dev Tracks failed transfers of native gas token 
     */
    mapping(address => uint256) failedTransferCredits;

    /**
     * @dev Blueprint, core object of contract
     */
    Blueprints public blueprint;

    /**
     * @dev Royalty config 
     */
    RoyaltyParameters public royaltyParameters;

    /**
     * @dev Contract-level metadata 
     */
    string public contractURI; 

    /**
     * @dev Holders of this role are given minter privileges 
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Tracks state of Blueprint sale
     */
    enum SaleState {
        not_prepared,
        not_started,
        started,
        paused
    }

    /**
     * @dev Object holding royalty data
     * @param split Royalty splitter receiving royalties
     * @param royaltyCutBPS Total percentage of token sales sent to split, in basis points 
     */
    struct RoyaltyParameters {
        address split;
        uint32 royaltyCutBPS;
    }

    /**
     * @dev Blueprint
     * @param mintAmountArtist Amount of NFTs of Blueprint mintable by artist
     * @param mintAmountPlatform Amount of NFTs of Blueprint mintable by platform 
     * @param capacity Number of NFTs in Blueprint 
     * @param erc721TokenIndex Token ID of last NFT minted for Blueprint
     * @param maxPurchaseAmount Max number of NFTs purchasable in a single transaction
     * @param saleEndTimestamp Timestamp when the sale ends 
     * @param price Price per NFT in Blueprint
     * @param tokenUriLocked If the token metadata isn't updatable 
     * @param ERC20Token Address of ERC20 currency required to buy NFTs, can be zero address if expected currency is native gas token 
     * @param baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param merkleroot Root of Merkle tree holding whitelisted accounts 
     * @param saleState State of sale
     * @param feeRecipientInfo Object containing primary and secondary fee configuration
     */ 
    struct Blueprints {
        uint32 mintAmountArtist;
        uint32 mintAmountPlatform;
        uint64 capacity;
        uint64 erc721TokenIndex;
        uint64 maxPurchaseAmount;
        uint128 saleEndTimestamp;
        uint128 price;
        bool tokenUriLocked;        
        address ERC20Token;
        string baseTokenUri;
        bytes32 merkleroot;
        SaleState saleState;    
        IBlueprintTypes.PrimaryFees feeRecipientInfo;
    }

    /**
     * @dev Creator config of contract
     * @param name Contract name
     * @param symbol Contract symbol
     * @param contractURI Contract-level metadata 
     * @param artist Blueprint artist
     */
    struct CreatorBlueprintsInput {
        string name;
        string symbol;
        string contractURI;
        address artist;
    }

    /**
     * @dev Emitted when blueprint seed is revealed
     * @param randomSeed Revealed seed
     */
    event BlueprintSeed(string randomSeed);

    /**
     * @dev Emitted when NFTs of blueprint are minted
     * @param artist Blueprint artist
     * @param purchaser Purchaser of NFTs
     * @param tokenId NFT minted
     * @param newCapacity New capacity of tokens left in blueprint 
     * @param seedPrefix Seed prefix hash
     */
    event BlueprintMinted(
        address artist,
        address purchaser,
        uint128 tokenId,
        uint64 newCapacity,
        bytes32 seedPrefix
    );

    /**
     * @dev Emitted when blueprint is prepared
     * @param artist Blueprint artist
     * @param capacity Number of NFTs in blueprint
     * @param blueprintMetaData Blueprint metadata uri
     * @param baseTokenUri Blueprint's base token uri. Token uris are a result of the base uri concatenated with token id 
     */ 
    event BlueprintPrepared(
        address artist,
        uint64 capacity,
        string blueprintMetaData,
        string baseTokenUri
    );

    /**
     * @dev Emitted when blueprint sale is started
     */
    event SaleStarted();

    /**
     * @dev Emitted when blueprint sale is paused
     */
    event SalePaused();

    /**
     * @dev Emitted when blueprint sale is unpaused
     */
    event SaleUnpaused();

    /**
     * @dev Emitted when blueprint token uri is updated 
     * @param newBaseTokenUri New base uri 
     */
    event BlueprintTokenUriUpdated(string newBaseTokenUri);

    /**
     * @dev Checks blueprint sale state
     */
    modifier isBlueprintPrepared() {
        require(
            blueprint.saleState != SaleState.not_prepared,
            "!prepared"
        );
        _;
    }

    /**
     * @dev Checks if blueprint sale is ongoing
     */
    modifier isSaleOngoing() {
        require(_isSaleOngoing(), "!ongoing");
        _;
    }

    /**
     * @dev Checks if quantity of NFTs is available for purchase in blueprint
     * @param _quantity Quantity of NFTs being checked 
     */ 
    modifier isQuantityAvailableForPurchase(
        uint32 _quantity
    ) {
        require(
            blueprint.capacity >= _quantity,
            "quantity >"
        );
        _;
    }

    /**
     * @dev Checks if sale is still valid, given the sale end timestamp 
     * @param _saleEndTimestamp Sale end timestamp 
     */ 
    modifier isSaleEndTimestampCurrentlyValid(
        uint128 _saleEndTimestamp
    ) {
        require(_isSaleEndTimestampCurrentlyValid(_saleEndTimestamp), "ended");
        _;
    }

    /**
     * @dev Validates royalty parameters. Allow null-equivalent values for certain use-cases
     * @param _royaltyParameters Royalty parameters 
     */
    modifier validRoyaltyParameters(
        RoyaltyParameters calldata _royaltyParameters
    ) {
        require(_royaltyParameters.royaltyCutBPS <= 10000);
        _;
    }

    /**
     * @dev Iniitalize the implementation 
     * @param creatorBlueprintsInput Core parameters for contract initialization 
     * @param creatorBlueprintsAdmins Administrative accounts 
     * @param _royaltyParameters Initial royalty settings 
     * @param extraMinter Additional address to give minter role
     */
    function initialize(
        CreatorBlueprintsInput calldata creatorBlueprintsInput,
        IBlueprintTypes.Admins calldata creatorBlueprintsAdmins,
        RoyaltyParameters calldata _royaltyParameters,
        address extraMinter
    ) public initializer validRoyaltyParameters(_royaltyParameters) {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(creatorBlueprintsInput.name, creatorBlueprintsInput.symbol);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, creatorBlueprintsAdmins.platform);
        _setupRole(MINTER_ROLE, creatorBlueprintsAdmins.minter);
        if (extraMinter != address(0)) {
            _setupRole(MINTER_ROLE, extraMinter);
        }

        platform = creatorBlueprintsAdmins.platform;
        minterAddress = creatorBlueprintsAdmins.minter;
        artist = creatorBlueprintsInput.artist;

        defaultPlatformPrimaryFeePercentage = 2000; // 20%

        asyncSaleFeesRecipient = creatorBlueprintsAdmins.asyncSaleFeesRecipient;
        contractURI = creatorBlueprintsInput.contractURI; 
        royaltyParameters = _royaltyParameters;
    }

    /**
     * @dev Validates that sale is still ongoing
     */
    function _isSaleOngoing()
        internal
        view
        returns (bool)
    {
        return blueprint.saleState == SaleState.started && _isSaleEndTimestampCurrentlyValid(blueprint.saleEndTimestamp);
    }

    /**
     * @dev Checks if user whitelisted for presale purchase
     * @param _whitelistedQuantity Purchaser's requested quantity. Validated against merkle tree
     * @param proof Corresponding proof for purchaser in merkle tree 
     */ 
    function _isWhitelistedAndPresale(
        uint32 _whitelistedQuantity,
        bytes32[] calldata proof
    )
        internal
        view
        returns (bool)
    {
        return (_isBlueprintPreparedAndNotStarted() && proof.length != 0 && _verify(_leaf(msg.sender, uint256(_whitelistedQuantity)), blueprint.merkleroot, proof));
    }
 
    /**
     * @dev Checks if sale is still valid, given the sale end timestamp 
     * @param _saleEndTimestamp Sale end timestamp 
     */  
    function _isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp)
        internal
        view
        returns (bool)
    {
        return _saleEndTimestamp > block.timestamp || _saleEndTimestamp == 0;
    }

    /**
     * @dev Checks that blueprint is prepared but sale for it hasn't started 
     */
    function _isBlueprintPreparedAndNotStarted()
        internal
        view
        returns (bool)
    {
        return blueprint.saleState == SaleState.not_started;
    }

    /**
     * @dev Checks that the recipients and allocations arrays of royalties are valid  
     * @param _feeRecipients Fee recipients
     * @param _feeBPS Allocations in percentages for fee recipients (basis points)
     */ 
    function feeArrayDataValid(
        address[] memory _feeRecipients,
        uint32[] memory _feeBPS
    ) internal pure returns (bool) {
        require(
            _feeRecipients.length == _feeBPS.length,
            "invalid"
        );
        uint32 totalPercent;
        for (uint256 i; i < _feeBPS.length; i++) {
            totalPercent = totalPercent + _feeBPS[i];
        }
        require(totalPercent <= 10000, "bps >");
        return true;
    }

    /**
     * @dev Sets values after blueprint preparation
     * @param _blueprintMetaData Blueprint metadata uri 
     */
    function setBlueprintPrepared(
        string memory _blueprintMetaData
    ) internal {
        blueprint.saleState = SaleState.not_started;
        //assign the erc721 token index to the blueprint
        blueprint.erc721TokenIndex = latestErc721TokenIndex;
        uint64 _capacity = blueprint.capacity;
        latestErc721TokenIndex += _capacity;

        emit BlueprintPrepared(
            artist,
            _capacity,
            _blueprintMetaData,
            blueprint.baseTokenUri
        );
    }

    /**
     * @dev Sets the ERC20 token value of a blueprint
     * @param _erc20Token ERC20 token being set
     */ 
    function setErc20Token(address _erc20Token) internal {
        if (_erc20Token != address(0)) {
            blueprint.ERC20Token = _erc20Token;
        }
    }

    /**
     * @dev Sets up most blueprint parameters 
     * @param _erc20Token ERC20 currency 
     * @param _baseTokenUri Base token uri for blueprint
     * @param _merkleroot Root of merkle tree allowlist
     * @param _mintAmountArtist Amount that artist can mint of blueprint
     * @param _mintAmountPlatform Amount that platform can mint of blueprint 
     * @param _maxPurchaseAmount Max amount of NFTs purchasable in one transaction
     * @param _saleEndTimestamp When the sale ends
     */
    function _setupBlueprint(
        address _erc20Token,
        string memory _baseTokenUri,
        bytes32 _merkleroot,
        uint32 _mintAmountArtist,
        uint32 _mintAmountPlatform,
        uint64 _maxPurchaseAmount,
        uint128 _saleEndTimestamp
    )   internal 
        isSaleEndTimestampCurrentlyValid(_saleEndTimestamp)
    {
        setErc20Token(_erc20Token);

        blueprint.baseTokenUri = _baseTokenUri;

        if (_merkleroot != 0) {
            blueprint.merkleroot = _merkleroot;
        }

        blueprint.mintAmountArtist = _mintAmountArtist;
        blueprint.mintAmountPlatform = _mintAmountPlatform;

        if (_maxPurchaseAmount != 0) {
            blueprint.maxPurchaseAmount = _maxPurchaseAmount;
        }
        
        if (_saleEndTimestamp != 0) {
            blueprint.saleEndTimestamp = _saleEndTimestamp;
        }
    }

    /** 
     * @dev Prepare the blueprint (this is the core operation to set up a blueprint)
     * @param config Object containing values required to prepare blueprint
     * @param _feeRecipientInfo Primary and secondary fees config
     */  
    function prepareBlueprint(
        IBlueprintTypes.BlueprintPreparationConfig calldata config,
        IBlueprintTypes.PrimaryFees calldata _feeRecipientInfo
    )   external 
        onlyRole(MINTER_ROLE)
    {
        blueprint.capacity = config._capacity;
        blueprint.price = config._price;

        _setupBlueprint(
            config._erc20Token,
            config._baseTokenUri,
            config._merkleroot,
            config._mintAmountArtist,
            config._mintAmountPlatform,
            config._maxPurchaseAmount,
            config._saleEndTimestamp
        );

        setBlueprintPrepared(config._blueprintMetaData);
        setFeeRecipients(_feeRecipientInfo);
    }

    /**
     * @dev Update a blueprint's artist
     * @param _newArtist New artist
     */
    function updateBlueprintArtist (
        address _newArtist
    ) external onlyRole(MINTER_ROLE) {
        artist = _newArtist;
    }

    /**
     * @dev Update a blueprint's capacity 
     * @param _newCapacity New capacity
     * @param _newLatestErc721TokenIndex Newly adjusted last ERC721 token id 
     */
    function updateBlueprintCapacity (
        uint64 _newCapacity,
        uint64 _newLatestErc721TokenIndex
    ) external onlyRole(MINTER_ROLE) {
        require(blueprint.capacity > _newCapacity, "New cap too large");

        blueprint.capacity = _newCapacity;

        latestErc721TokenIndex = _newLatestErc721TokenIndex;
    }

    /**
     * @dev Set the primary fees config of blueprint
     * @param _feeRecipientInfo Fees config 
     */
    function setFeeRecipients(
        IBlueprintTypes.PrimaryFees memory _feeRecipientInfo
    ) public onlyRole(MINTER_ROLE) {
        require(
            blueprint.saleState != SaleState.not_prepared,
            "never prepared"
        );
        if (feeArrayDataValid(_feeRecipientInfo.primaryFeeRecipients, _feeRecipientInfo.primaryFeeBPS)) {
            blueprint.feeRecipientInfo = _feeRecipientInfo;
        }
    }

    /**
     * @dev Begin blueprint's sale
     */
    function beginSale()
        external
        onlyRole(MINTER_ROLE)
        isSaleEndTimestampCurrentlyValid(blueprint.saleEndTimestamp) 
    {
        require(
            blueprint.saleState == SaleState.not_started,
            "sale started or not prepared"
        );
        blueprint.saleState = SaleState.started;
        emit SaleStarted();
    }

    /**
     * @dev Pause blueprint's sale
     */
    function pauseSale()
        external
        onlyRole(MINTER_ROLE)
        isSaleOngoing()
    {
        blueprint.saleState = SaleState.paused;
        emit SalePaused();
    }

    /**
     * @dev Unpause blueprint's sale
     */
    function unpauseSale() external onlyRole(MINTER_ROLE) isSaleEndTimestampCurrentlyValid(blueprint.saleEndTimestamp) {
        require(
            blueprint.saleState == SaleState.paused,
            "!paused"
        );
        blueprint.saleState = SaleState.started;
        emit SaleUnpaused();
    }

    /**
     * @dev Update blueprint's merkle tree root 
     * @param oldProof Old proof for leaf being updated, used for validation 
     * @param remainingWhitelistAmount Remaining whitelist amount of NFTs 
     */
    function _updateMerkleRootForPurchase(
        bytes32[] memory oldProof,
        uint32 remainingWhitelistAmount
    ) 
        internal
    {
        bool[] memory proofFlags = new bool[](oldProof.length);
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _leaf(msg.sender, uint256(remainingWhitelistAmount));
        blueprint.merkleroot = MerkleProof.processMultiProof(oldProof, proofFlags, leaves);
    }

    /**
     * @dev Purchase NFTs of blueprint to a recipient address
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     * @param nftRecipient Recipient of minted NFTs
     */
    function purchaseBlueprintsTo(
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof,
        address nftRecipient
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(whitelistedQuantity, proof)) {
            require(purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            _updateMerkleRootForPurchase(proof, whitelistedQuantity - purchaseQuantity);
        } else {
            require(_isSaleOngoing(), "unavailable");
        }

        require(
            blueprint.maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprint.maxPurchaseAmount,
            "cannot buy > maxPurchaseAmount in one tx"
        );

        _confirmPaymentAmountAndSettleSale(
            purchaseQuantity,
            tokenAmount,
            artist
        );
        _mintQuantity(purchaseQuantity, nftRecipient);
    }

    /**
     * @dev Purchase NFTs of blueprint to the sender
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     */ 
    function purchaseBlueprints(
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(whitelistedQuantity, proof)) {
            require(purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            _updateMerkleRootForPurchase(proof, whitelistedQuantity - purchaseQuantity);
        } else {
            require(_isSaleOngoing(), "unavailable");
        }

        require(
            blueprint.maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprint.maxPurchaseAmount,
            "cannot buy > maxPurchaseAmount in one tx"
        );

        _confirmPaymentAmountAndSettleSale(
            purchaseQuantity,
            tokenAmount,
            artist
        );

        _mintQuantity(purchaseQuantity, msg.sender);
    }

    /**
     * @dev Lets the artist mint NFTs of the blueprint
     * @param quantity How many NFTs to mint
     */
    function artistMint(
        uint32 quantity
    )
        external
        nonReentrant 
    {
        address _artist = artist; // cache
        require(
            _isBlueprintPreparedAndNotStarted() || _isSaleOngoing(),
            "not pre/public sale"
        );
        require(
            minterAddress == msg.sender ||
                _artist == msg.sender,
            "unauthorized"
        );

        if (minterAddress == msg.sender) {
            require(
                quantity <= blueprint.mintAmountPlatform,
                "quantity >"
            );
            blueprint.mintAmountPlatform -= quantity;
        } else if (_artist == msg.sender) {
            require(
                quantity <= blueprint.mintAmountArtist,
                "quantity >"
            );
            blueprint.mintAmountArtist -= quantity;
        }
        _mintQuantity(quantity, msg.sender);
    }

    /**
     * @dev Mint a quantity of NFTs of blueprint to a recipient 
     * @param _quantity Quantity to mint
     * @param _nftRecipient Recipient of minted NFTs
     */
    function _mintQuantity(uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprint.erc721TokenIndex;
        uint64 newCap = blueprint.capacity;
        for (uint16 i; i < _quantity; i++) {
            require(newCap > 0, "quantity > cap");
            
            _mint(_nftRecipient, newTokenId + i);

            bytes32 prefixHash = keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.coinbase,
                    newCap
                )
            );
            emit BlueprintMinted(
                artist,
                _nftRecipient,
                newTokenId + i,
                newCap,
                prefixHash
            );
            --newCap;
        }

        blueprint.erc721TokenIndex += _quantity;
        blueprint.capacity = newCap;
    }

    /**
     * @dev Pay for minting NFTs 
     * @param _quantity Quantity of NFTs to purchase
     * @param _tokenAmount Payment amount provided
     * @param _artist Artist of blueprint
     */
    function _confirmPaymentAmountAndSettleSale(
        uint32 _quantity,
        uint256 _tokenAmount,
        address _artist
    ) internal {
        address _erc20Token = blueprint.ERC20Token;
        uint128 _price = blueprint.price;
        if (_erc20Token == address(0)) {
            require(_tokenAmount == 0, "tokenAmount != 0");
            require(
                msg.value == _quantity * _price,
                "$ != expected"
            );
            _payFeesAndArtist(_erc20Token, msg.value, _artist);
        } else {
            require(msg.value == 0, "eth value != 0");
            require(
                _tokenAmount == _quantity * _price,
                "$ != expected"
            );

            IERC20(_erc20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            _payFeesAndArtist(_erc20Token, _tokenAmount, _artist);
        }
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * Create a merkle tree with address: quantity pairs as the leaves.
     * The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     */

    /**
     * @dev Create a merkle tree with address: quantity pairs as the leaves.
     *      The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     * @param account Minting account being verified
     * @param quantity Quantity to mint, being verified
     */ 
    function _leaf(address account, uint256 quantity)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, quantity));
    }

    /**
     * @dev Verify a leaf's inclusion in a merkle tree with its root and corresponding proof
     * @param leaf Leaf to verify
     * @param merkleroot Merkle tree's root
     * @param proof Corresponding proof for leaf
     */ 
    function _verify(
        bytes32 leaf,
        bytes32 merkleroot,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @dev Update blueprint's token uri
     * @param newBaseTokenUri New base token uri to update to
     */ 
    function updateBlueprintTokenUri(
        string memory newBaseTokenUri
    ) external onlyRole(MINTER_ROLE) isBlueprintPrepared() {
        require(
            !blueprint.tokenUriLocked,
            "URI locked"
        );

        blueprint.baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(newBaseTokenUri);
    }

    /**
     * @dev Lock blueprint's token uri (from changing)
     */  
    function lockBlueprintTokenUri()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isBlueprintPrepared()
    {
        require(
            !blueprint.tokenUriLocked,
            "URI locked"
        );

        blueprint.tokenUriLocked = true;
    }

    /**
     * @dev Return token's uri
     * @param tokenId ID of token to return uri for
     * @return Token uri, constructed by taking base uri of blueprint, and concatenating token id
     */ 
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "URI query for nonexistent token"
        );

        string memory baseURI = blueprint.baseTokenUri;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        tokenId.toString(),
                        "/",
                        "token.json"
                    )
                )
                : "";
    }

    /**
     * @dev Reveal blueprint's seed by emitting public event 
     * @param randomSeed Revealed seed 
     */
    function revealBlueprintSeed(string memory randomSeed)
        external
        onlyRole(MINTER_ROLE)
        isBlueprintPrepared()
    {
        emit BlueprintSeed(randomSeed);
    }

    /**
     * @dev Set the contract-wide recipient of primary sale feess
     * @param _asyncSaleFeesRecipient New async sale fees recipient 
     */
    function setAsyncFeeRecipient(address _asyncSaleFeesRecipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        asyncSaleFeesRecipient = _asyncSaleFeesRecipient;
    }

    /**
     * @dev Change the default percentage of primary sales sent to platform
     * @param _basisPoints New default platform primary fee percentage (in basis points)
     */   
    function changeDefaultPlatformPrimaryFeePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints <= 10000);
        defaultPlatformPrimaryFeePercentage = _basisPoints;
    }

    /**
     * @dev Update royalty config
     * @param _royaltyParameters New royalty parameters
     */  
    function updateRoyaltyParameters(RoyaltyParameters calldata _royaltyParameters) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        validRoyaltyParameters(_royaltyParameters)
    {
        royaltyParameters = _royaltyParameters; 
    }

    /**
     * @dev Update contract-wide platform address, and DEFAULT_ADMIN role ownership
     * @param _platform New platform address
     */   
    function updatePlatformAddress(address _platform)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @dev Update contract-wide minter address, and MINTER_ROLE role ownership
     * @param newMinterAddress New minter address
     */ 
    function updateMinterAddress(address newMinterAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, newMinterAddress);

        revokeRole(MINTER_ROLE, minterAddress);
        minterAddress = newMinterAddress;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    /**
     * @dev Pay primary fees owed to primary fee recipients
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     * @param _artist Artist being paid
     */
    function _payFeesAndArtist(
        address _erc20Token,
        uint256 _amount,
        address _artist
    ) internal {
        address[] memory _primaryFeeRecipients = getPrimaryFeeRecipients();
        uint32[] memory _primaryFeeBPS = getPrimaryFeeBps();
        uint256 feesPaid;

        for (uint256 i; i < _primaryFeeRecipients.length; i++) {
            uint256 fee = (_amount * _primaryFeeBPS[i])/10000;
            feesPaid = feesPaid + fee;
            _payout(_primaryFeeRecipients[i], _erc20Token, fee);
        }
        if (_amount - feesPaid > 0) {
            _payout(_artist, _erc20Token, (_amount - feesPaid));
        }
    }

    /**
     * @dev Simple payment function to pay an amount of currency to a recipient
     * @param _recipient Recipient of payment 
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     */
    function _payout(
        address _recipient,
        address _erc20Token,
        uint256 _amount
    ) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    /**
     * @dev When a native gas token payment fails, credits are stored so that the would-be recipient can withdraw them later.
     *      Withdraw failed credits for a recipient
     * @param recipient Recipient owed some amount of native gas token   
     */
    function withdrawAllFailedCredits(address payable recipient) external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = recipient.call{value: amount, gas: 20000}(
            ""
        );
        require(successfulWithdraw, "withdraw failed");
    }

    /**
     * @dev Get primary fee recipients of blueprint 
     */ 
    function getPrimaryFeeRecipients()
        public
        view
        returns (address[] memory)
    {
        if (blueprint.feeRecipientInfo.primaryFeeRecipients.length == 0) {
            address[] memory primaryFeeRecipients = new address[](1);
            primaryFeeRecipients[0] = (asyncSaleFeesRecipient);
            return primaryFeeRecipients;
        } else {
            return blueprint.feeRecipientInfo.primaryFeeRecipients;
        }
    }

    /**
     * @dev Get primary fee bps (allocations) of blueprint 
     */
    function getPrimaryFeeBps()
        public
        view
        returns (uint32[] memory)
    {
        if (blueprint.feeRecipientInfo.primaryFeeBPS.length == 0) {
            uint32[] memory primaryFeeBPS = new uint32[](1);
            primaryFeeBPS[0] = defaultPlatformPrimaryFeePercentage;

            return primaryFeeBPS;
        } else {
            return blueprint.feeRecipientInfo.primaryFeeBPS;
        }
    }

    /**
     * @dev Get secondary fee recipients of a token 
     * @param tokenId Token ID
     */
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory feeRecipients = new address[](1);
        feeRecipients[0] = royaltyParameters.split;
        return feeRecipients;
    }

    /**
     * @dev Get secondary fee bps (allocations) of a token 
     * @param tokenId Token ID
     */
    function getFeeBps(uint256 tokenId)
        public
        view
        override
        returns (uint32[] memory)
    {
        uint32[] memory feeBps = new uint32[](1);
        feeBps[0] = royaltyParameters.royaltyCutBPS;
        return feeBps;
    }

    /**
     * @dev Support ERC-2981
     * @param _tokenId ID of token to return royalty for
     * @param _salePrice Price that NFT was sold at
     * @return receiver Royalty split
     * @return royaltyAmount Amount to send to royalty split
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = royaltyParameters.split;
        royaltyAmount = _salePrice * royaltyParameters.royaltyCutBPS / 10000;
    }

    /**
     * @dev Used for interoperability purposes
     * @return Returns platform address as owner of contract 
     */
    function owner() public view virtual returns (address) {
        return platform;
    }

    ////////////////////////////////////
    /// Required function overide //////
    ////////////////////////////////////

    /**
     * @dev Override isApprovedForAll to also let the DEFAULT_ADMIN_ROLE move tokens
     * @param account Account holding tokens being moved
     * @param operator Operator moving tokens
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(account, operator) ||
            hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    /**
     * @dev ERC165 - Validate that the contract supports a interface
     * @param interfaceId ID of interface being validated 
     * @return Returns true if contract supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC165StorageUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(HasSecondarySaleFees).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }
}

abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
}

/**
 * @dev Global instance of Async Art Blueprint NFTs
 * @author Async Art, Ohimire Labs
 */
contract BlueprintV12 is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuard
{
    using StringsUpgradeable for uint256;

    /**
     * @dev Default fee given to platform on primary sales
     */
    uint32 public defaultPlatformPrimaryFeePercentage;   

    /**
     * @dev Default fee given to artist on secondary sales
     */ 
    uint32 public defaultBlueprintSecondarySalePercentage;

    /**
     * @dev Default fee given to platoform on secondary sales
     */ 
    uint32 public defaultPlatformSecondarySalePercentage;

    /**
     * @dev Token id of last ERC721 NFT minted
     */ 
    uint64 public latestErc721TokenIndex;

    /**
     * @dev Id of last blueprint created
     */
    uint256 public blueprintIndex;

    /**
     * @dev Platform account receiving fees from primary sales
     */
    address public asyncSaleFeesRecipient;

    /**
     * @dev Account representing platform 
     */
    address public platform;

    /**
     * @dev Account able to perform actions restricted to MINTER_ROLE holder
     */
    address public minterAddress;

    /** 
     * @dev Royalty manager 
     */
    address private _splitMain;
    
    /**
     * @dev Maps NFT ids to id of associated blueprint 
     */
    mapping(uint256 => uint256) tokenToBlueprintID;

    /**
     * @dev Tracks failed transfers of native gas token 
     */
    mapping(address => uint256) failedTransferCredits;

    /**
     * @dev Stores all Blueprints 
     */
    mapping(uint256 => Blueprints) public blueprints;

    /**
     * @dev Holders of this role are given minter privileges 
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Tracks state of Blueprint sale
     */
    enum SaleState {
        not_prepared,
        not_started,
        started,
        paused
    }

    /**
     * @dev Object used by contract clients to efficiently pass in desired configuration for royalties for a Blueprint
     * @param secondaryFeeRecipients Array of royalty recipients
     * @param secondaryFeeMPS Array of allocations given to each royalty recipients, where 1000000 = 100%
     * @param totalRoyaltyCutBPS Total percentage of token purchase to be sent to royalty recipients, in basis points
     * @param royaltyRecipient If/when this is not the zero address, it is used as the de-facto alternative to secondaryFeeRecipients and secondaryFeeBPS
     */
    struct SecondaryFeesInput {
        address[] secondaryFeeRecipients; 
        uint32[] secondaryFeeMPS; 
        uint32 totalRoyaltyCutBPS;
        address royaltyRecipient;
    }

    /**
     * @dev Object used by contract clients to efficiently pass in desired configuration for all fees 
     * @param primaryFeeBPS Array of allocations given to each primary fee recipient, in basis points
     * @param primaryFeeRecipients Array of primary fee recipients
     * @param secondaryFeesInput Contains desired configuration for royalties
     * @param deploySplit If true, function taking FeesInput instance will deploy a royalty split 
     */
    struct FeesInput {
        uint32[] primaryFeeBPS;
        address[] primaryFeeRecipients;
        SecondaryFeesInput secondaryFeesInput;
        bool deploySplit; 
    } 

    /**
     * @dev Object stored per Blueprint defining fee recipients and allocations
     * @param primaryFeeRecipients Array of primary fee recipients
     * @param primaryFeeBPS Array of allocations given to each primary fee recipient, in basis points
     * @param royaltyRecipient Address to receive total share of royalties. Expected to be royalty split or important account
     * @param totalRoyaltyCutBPS Total percentage of token purchase to be sent to royalty recipients, in basis points
     */
    struct Fees {
        address[] primaryFeeRecipients;
        uint32[] primaryFeeBPS;
        address royaltyRecipient;
        uint32 totalRoyaltyCutBPS;
    }

    /**
     * @dev Blueprint
     * @param mintAmountArtist Amount of NFTs of Blueprint mintable by artist
     * @param mintAmountArtist Amount of NFTs of Blueprint mintable by platform 
     * @param capacity Number of NFTs in Blueprint 
     * @param erc721TokenIndex Token ID of last NFT minted for Blueprint
     * @param maxPurchaseAmount Max number of NFTs purchasable in a single transaction
     * @param saleEndTimestamp Timestamp when the sale ends 
     * @param price Price per NFT in Blueprint
     * @param tokenUriLocked If the token metadata isn't updatable 
     * @param artist Artist of Blueprint
     * @param ERC20Token Address of ERC20 currency required to buy NFTs, can be zero address if expected currency is native gas token 
     * @param baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param merkleroot Root of Merkle tree holding whitelisted accounts 
     * @param saleState State of sale
     * @param feeRecipientInfo Object containing primary and secondary fee configuration
     */ 
    struct Blueprints {
        uint32 mintAmountArtist;
        uint32 mintAmountPlatform;
        uint64 capacity;
        uint64 erc721TokenIndex;
        uint64 maxPurchaseAmount;
        uint128 saleEndTimestamp;
        uint128 price;
        bool tokenUriLocked;        
        address artist;
        address ERC20Token;
        string baseTokenUri;
        bytes32 merkleroot;
        SaleState saleState;    
        Fees feeRecipientInfo;
    }

    /**
     * @dev Emitted when blueprint seed is revealed
     * @param blueprintID ID of blueprint
     * @param randomSeed Revealed seed
     */
    event BlueprintSeed(uint256 blueprintID, string randomSeed);

    /**
     * @dev Emitted when NFTs of a blueprint are minted
     * @param blueprintID ID of blueprint
     * @param artist Blueprint artist
     * @param purchaser Purchaser of NFTs
     * @param tokenId NFT minted
     * @param newCapacity New capacity of tokens left in blueprint 
     * @param seedPrefix Seed prefix hash
     */
    event BlueprintMinted(
        uint256 blueprintID,
        address artist,
        address purchaser,
        uint128 tokenId,
        uint64 newCapacity,
        bytes32 seedPrefix
    );

    /**
     * @dev Emitted when blueprint is prepared
     * @param blueprintID ID of blueprint
     * @param artist Blueprint artist
     * @param capacity Number of NFTs in blueprint
     * @param blueprintMetaData Blueprint metadata uri
     * @param baseTokenUri Blueprint's base token uri. Token uris are a result of the base uri concatenated with token id 
     */
    event BlueprintPrepared(
        uint256 blueprintID,
        address artist,
        uint64 capacity,
        string blueprintMetaData,
        string baseTokenUri
    );
    
    /**
     * @dev Emitted when blueprint sale is started
     * @param blueprintID ID of blueprint
     */
    event SaleStarted(uint256 blueprintID);

    /**
     * @dev Emitted when blueprint sale is paused
     * @param blueprintID ID of blueprint
     */
    event SalePaused(uint256 blueprintID);

    /**
     * @dev Emitted when blueprint sale is unpaused
     * @param blueprintID ID of blueprint
     */
    event SaleUnpaused(uint256 blueprintID);

    /**
     * @dev Emitted when blueprint token uri is updated 
     * @param blueprintID ID of blueprint
     * @param newBaseTokenUri New base uri 
     */
    event BlueprintTokenUriUpdated(uint256 blueprintID, string newBaseTokenUri);

    /**
     * @dev Checks blueprint sale state
     * @param _blueprintID ID of blueprint 
     */
    modifier isBlueprintPrepared(uint256 _blueprintID) {
        require(
            blueprints[_blueprintID].saleState != SaleState.not_prepared,
            "!prepared"
        );
        _;
    }

    /**
     * @dev Checks if blueprint sale is ongoing
     * @param _blueprintID ID of blueprint 
     */
    modifier isSaleOngoing(uint256 _blueprintID) {
        require(_isSaleOngoing(_blueprintID), "!ongoing");
        _;
    }

    /**
     * @dev Checks if quantity of NFTs is available for purchase in blueprint
     * @param _blueprintID ID of blueprint 
     * @param _quantity Quantity of NFTs being checked 
     */ 
    modifier isQuantityAvailableForPurchase(
        uint256 _blueprintID,
        uint32 _quantity
    ) {
        require(
            blueprints[_blueprintID].capacity >= _quantity,
            "quantity >"
        );
        _;
    }

    /**
     * @dev Checks if sale is still valid, given the sale end timestamp 
     * @param _saleEndTimestamp Sale end timestamp 
     */ 
    modifier isSaleEndTimestampCurrentlyValid(
        uint128 _saleEndTimestamp
    ) {
        require(_isSaleEndTimestampCurrentlyValid(_saleEndTimestamp), "ended");
        _;
    }

    /**
     * @dev Initialize the implementation 
     * @param name_ Contract name
     * @param symbol_ Contract symbol
     * @param blueprintV12Admins Administrative accounts  
     * @param splitMain Royalty manager
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        IBlueprintTypes.Admins calldata blueprintV12Admins,
        address splitMain
    ) public initializer {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, blueprintV12Admins.platform);
        _setupRole(MINTER_ROLE, blueprintV12Admins.minter);

        platform = blueprintV12Admins.platform;
        minterAddress = blueprintV12Admins.minter;

        defaultPlatformPrimaryFeePercentage = 2000; // 20%

        defaultBlueprintSecondarySalePercentage = 750; // 7.5%
        defaultPlatformSecondarySalePercentage = 250; // 2.5%

        asyncSaleFeesRecipient = blueprintV12Admins.asyncSaleFeesRecipient;
        _splitMain = splitMain;
    }

    /**
     * @dev Validates that sale is still ongoing
     * @param _blueprintID Blueprint ID 
     */
    function _isSaleOngoing(uint256 _blueprintID)
        internal
        view
        returns (bool)
    {
        return blueprints[_blueprintID].saleState == SaleState.started && _isSaleEndTimestampCurrentlyValid(blueprints[_blueprintID].saleEndTimestamp);
    }

    /**
     * @dev Checks if user whitelisted for presale purchase 
     * @param _blueprintID ID of blueprint 
     * @param _whitelistedQuantity Purchaser's requested quantity. Validated against merkle tree
     * @param proof Corresponding proof for purchaser in merkle tree 
     */ 
    function _isWhitelistedAndPresale(
        uint256 _blueprintID,
        uint32 _whitelistedQuantity,
        bytes32[] calldata proof
    )
        internal
        view
        returns (bool)
    {
        return (_isBlueprintPreparedAndNotStarted(_blueprintID) && proof.length != 0 && _verify(_leaf(msg.sender, uint256(_whitelistedQuantity)), blueprints[_blueprintID].merkleroot, proof));
    }

    /**
     * @dev Checks if sale is still valid, given the sale end timestamp 
     * @param _saleEndTimestamp Sale end timestamp 
     */  
    function _isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp)
        internal
        view
        returns (bool)
    {
        return _saleEndTimestamp > block.timestamp || _saleEndTimestamp == 0;
    }

    /**
     * @dev Checks that blueprint is prepared but sale for it hasn't started 
     * @param _blueprintID ID of blueprint 
     */
    function _isBlueprintPreparedAndNotStarted(uint256 _blueprintID)
        internal
        view
        returns (bool)
    {
        return blueprints[_blueprintID].saleState == SaleState.not_started;
    }

    /**
     * @dev Checks that the recipients and allocations arrays of royalties are valid  
     * @param _feeRecipients Fee recipients
     * @param _feeBPS Allocations in percentages for fee recipients (basis points)
     */ 
    function feeArrayDataValid(
        address[] memory _feeRecipients,
        uint32[] memory _feeBPS
    ) internal pure returns (bool) {
        require(
            _feeRecipients.length == _feeBPS.length,
            "invalid"
        );
        uint32 totalPercent;
        for (uint256 i; i < _feeBPS.length; i++) {
            totalPercent = totalPercent + _feeBPS[i];
        }
        require(totalPercent <= 10000, "bps >");
        return true;
    }

    /**
     * @dev Sets values after blueprint preparation
     * @param _blueprintID Blueprint ID
     * @param _blueprintMetaData Blueprint metadata uri 
     */
    function setBlueprintPrepared(
        uint256 _blueprintID,
        string memory _blueprintMetaData
    ) internal {
        blueprints[_blueprintID].saleState = SaleState.not_started;
        //assign the erc721 token index to the blueprint
        blueprints[_blueprintID].erc721TokenIndex = latestErc721TokenIndex;
        uint64 _capacity = blueprints[_blueprintID].capacity;
        latestErc721TokenIndex += _capacity;
        blueprintIndex++;

        emit BlueprintPrepared(
            _blueprintID,
            blueprints[_blueprintID].artist,
            _capacity,
            _blueprintMetaData,
            blueprints[_blueprintID].baseTokenUri
        );
    }

    /**
     * @dev Sets the ERC20 token value of a blueprint
     * @param _blueprintID Blueprint ID 
     * @param _erc20Token ERC20 token being set
     */
    function setErc20Token(uint256 _blueprintID, address _erc20Token) internal {
        if (_erc20Token != address(0)) {
            blueprints[_blueprintID].ERC20Token = _erc20Token;
        }
    }

    /**
     * @dev Sets up most blueprint parameters 
     * @param _blueprintID Blueprint ID 
     * @param _erc20Token ERC20 currency 
     * @param _baseTokenUri Base token uri for blueprint
     * @param _merkleroot Root of merkle tree allowlist
     * @param _mintAmountArtist Amount that artist can mint of blueprint
     * @param _mintAmountPlatform Amount that platform can mint of blueprint 
     * @param _maxPurchaseAmount Max amount of NFTs purchasable in one transaction
     * @param _saleEndTimestamp When the sale ends
     */
    function _setupBlueprint(
        uint256 _blueprintID,
        address _erc20Token,
        string memory _baseTokenUri,
        bytes32 _merkleroot,
        uint32 _mintAmountArtist,
        uint32 _mintAmountPlatform,
        uint64 _maxPurchaseAmount,
        uint128 _saleEndTimestamp
    )   internal 
        isSaleEndTimestampCurrentlyValid(_saleEndTimestamp)
    {
        setErc20Token(_blueprintID, _erc20Token);

        blueprints[_blueprintID].baseTokenUri = _baseTokenUri;

        if (_merkleroot != 0) {
            blueprints[_blueprintID].merkleroot = _merkleroot;
        }

        blueprints[_blueprintID].mintAmountArtist = _mintAmountArtist;
        blueprints[_blueprintID].mintAmountPlatform = _mintAmountPlatform;

        if (_maxPurchaseAmount != 0) {
            blueprints[_blueprintID].maxPurchaseAmount = _maxPurchaseAmount;
        }
        
        if (_saleEndTimestamp != 0) {
            blueprints[_blueprintID].saleEndTimestamp = _saleEndTimestamp;
        }
    }

    
    /** 
     * @dev Prepare the blueprint (this is the core operation to set up a blueprint)
     * @param _artist Artist address
     * @param config Object containing values required to prepare blueprint
     * @param feesInput Initial primary and secondary fees config
     */ 
    function prepareBlueprint(
        address _artist,
        IBlueprintTypes.BlueprintPreparationConfig calldata config,
        FeesInput calldata feesInput
    )   external 
        onlyRole(MINTER_ROLE)
    {
        uint256 _blueprintID = blueprintIndex;
        blueprints[_blueprintID].artist = _artist;
        blueprints[_blueprintID].capacity = config._capacity;
        blueprints[_blueprintID].price = config._price;

        _setupBlueprint(
            _blueprintID,
            config._erc20Token,
            config._baseTokenUri,
            config._merkleroot,
            config._mintAmountArtist,
            config._mintAmountPlatform,
            config._maxPurchaseAmount,
            config._saleEndTimestamp
        ); 

        setBlueprintPrepared(_blueprintID, config._blueprintMetaData);
        setFeeRecipients(_blueprintID, feesInput);
    }

    /**
     * @dev Update a blueprint's artist
     * @param _blueprintID Blueprint ID 
     * @param _newArtist New artist
     */
    function updateBlueprintArtist (
        uint256 _blueprintID,
        address _newArtist
    ) external onlyRole(MINTER_ROLE) {
        blueprints[_blueprintID].artist = _newArtist;
    }

    /**
     * @dev Update a blueprint's capacity
     * @param _blueprintID Blueprint ID 
     * @param _newCapacity New capacity
     * @param _newLatestErc721TokenIndex Newly adjusted last ERC721 token id 
     */
    function updateBlueprintCapacity (
        uint256 _blueprintID,
        uint64 _newCapacity,
        uint64 _newLatestErc721TokenIndex
    ) external onlyRole(MINTER_ROLE) {
        require(blueprints[_blueprintID].capacity > _newCapacity, "cap >");

        blueprints[_blueprintID].capacity = _newCapacity;

        latestErc721TokenIndex = _newLatestErc721TokenIndex;
    }

    /**
     * @dev Set the primary and secondary fees config of a blueprint
     * @param _blueprintID Blueprint ID
     * @param _feesInput Fees config 
     */
    function setFeeRecipients(
        uint256 _blueprintID,
        FeesInput memory _feesInput
    ) public onlyRole(MINTER_ROLE) {
        require(
            blueprints[_blueprintID].saleState != SaleState.not_prepared,
            "!prepared"
        );
        require(
            feeArrayDataValid(_feesInput.primaryFeeRecipients, _feesInput.primaryFeeBPS),
            "primary"
        ); 

        SecondaryFeesInput memory secondaryFeesInput = _feesInput.secondaryFeesInput;

        Fees memory feeRecipientInfo = Fees(
            _feesInput.primaryFeeRecipients,
            _feesInput.primaryFeeBPS,
            secondaryFeesInput.royaltyRecipient, 
            secondaryFeesInput.totalRoyaltyCutBPS
        );

        // if pre-existing split isn't passed in, deploy it and set it. 
        if (_feesInput.deploySplit) {
            feeRecipientInfo.royaltyRecipient = ISplitMain(_splitMain).createSplit(
                secondaryFeesInput.secondaryFeeRecipients, 
                secondaryFeesInput.secondaryFeeMPS, 
                0, 
                address(0) // immutable split
            );
        } 
        
        blueprints[_blueprintID].feeRecipientInfo = feeRecipientInfo;
    }

    /**
     * @dev Begin a blueprint's sale
     * @param blueprintID Blueprint ID 
     */
    function beginSale(uint256 blueprintID)
        external
        onlyRole(MINTER_ROLE)
        isSaleEndTimestampCurrentlyValid(blueprints[blueprintID].saleEndTimestamp) 
    {
        require(
            blueprints[blueprintID].saleState == SaleState.not_started,
            "started"
        );
        blueprints[blueprintID].saleState = SaleState.started;
        emit SaleStarted(blueprintID);
    }

    /**
     * @dev Pause a blueprint's sale
     * @param blueprintID Blueprint ID 
     */
    function pauseSale(uint256 blueprintID)
        external
        onlyRole(MINTER_ROLE)
        isSaleOngoing(blueprintID)
    {
        blueprints[blueprintID].saleState = SaleState.paused;
        emit SalePaused(blueprintID);
    }

    /**
     * @dev Unpause a blueprint's sale
     * @param blueprintID Blueprint ID 
     */
    function unpauseSale(uint256 blueprintID) external onlyRole(MINTER_ROLE) isSaleEndTimestampCurrentlyValid(blueprints[blueprintID].saleEndTimestamp) {
        require(
            blueprints[blueprintID].saleState == SaleState.paused,
            "!paused"
        );
        blueprints[blueprintID].saleState = SaleState.started;
        emit SaleUnpaused(blueprintID);
    }

    /**
     * @dev Update a blueprint's merkle tree root 
     * @param blueprintID Blueprint ID 
     * @param oldProof Old proof for leaf being updated, used for validation 
     * @param remainingWhitelistAmount Remaining whitelist amount of NFTs 
     */
    function _updateMerkleRootForPurchase(
        uint256 blueprintID,
        bytes32[] memory oldProof,
        uint32 remainingWhitelistAmount
    ) 
        internal
    {
        bool[] memory proofFlags = new bool[](oldProof.length);
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _leaf(msg.sender, uint256(remainingWhitelistAmount));
        blueprints[blueprintID].merkleroot = MerkleProof.processMultiProof(oldProof, proofFlags, leaves);
    }

    /**
     * @dev Purchase NFTs of a blueprint to a recipient address
     * @param blueprintID Blueprint ID
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     * @param nftRecipient Recipient of minted NFTs
     */
    function purchaseBlueprintsTo(
        uint256 blueprintID,
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof,
        address nftRecipient
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(blueprintID, purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(blueprintID, whitelistedQuantity, proof)) {
            require(purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            _updateMerkleRootForPurchase(blueprintID, proof, whitelistedQuantity - purchaseQuantity);
        } else {
            require(_isSaleOngoing(blueprintID), "unavailable");
        }

        require(
            blueprints[blueprintID].maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprints[blueprintID].maxPurchaseAmount,
            "> maxPurchaseAmount"
        );

        address artist = blueprints[blueprintID].artist;
        _confirmPaymentAmountAndSettleSale(
            blueprintID,
            purchaseQuantity,
            tokenAmount,
            artist
        );
        _mintQuantity(blueprintID, purchaseQuantity, nftRecipient);
    }

    /**
     * @dev Purchase NFTs of a blueprint to the sender
     * @param blueprintID Blueprint ID
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     */ 
    function purchaseBlueprints(
        uint256 blueprintID,
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(blueprintID, purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(blueprintID, whitelistedQuantity, proof)) {
            require(purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            _updateMerkleRootForPurchase(blueprintID, proof, whitelistedQuantity - purchaseQuantity);
        } else {
            require(_isSaleOngoing(blueprintID), "unavailable");
        }

        require(
            blueprints[blueprintID].maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprints[blueprintID].maxPurchaseAmount,
            "> maxPurchaseAmount"
        );

        address artist = blueprints[blueprintID].artist;
        _confirmPaymentAmountAndSettleSale(
            blueprintID,
            purchaseQuantity,
            tokenAmount,
            artist
        );
        _mintQuantity(blueprintID, purchaseQuantity, msg.sender);
    }

    /**
     * @dev Lets the artist of a blueprint mint NFTs of the blueprint
     * @param blueprintID Blueprint ID
     * @param quantity How many NFTs to mint
     */
    function artistMint(
        uint256 blueprintID,
        uint32 quantity
    )
        external
        nonReentrant 
    {
        require(
            _isBlueprintPreparedAndNotStarted(blueprintID) || _isSaleOngoing(blueprintID),
            "not pre/public sale"
        );
        require(
            minterAddress == msg.sender ||
                blueprints[blueprintID].artist == msg.sender,
            "unauthorized"
        );

        if (minterAddress == msg.sender) {
            require(
                quantity <= blueprints[blueprintID].mintAmountPlatform,
                "quantity >"
            );
            blueprints[blueprintID].mintAmountPlatform -= quantity;
        } else if (blueprints[blueprintID].artist == msg.sender) {
            require(
                quantity <= blueprints[blueprintID].mintAmountArtist,
                "quantity >"
            );
            blueprints[blueprintID].mintAmountArtist -= quantity;
        }
        _mintQuantity(blueprintID, quantity, msg.sender);
    }

    /**
     * @dev Mint a quantity of NFTs of a blueprint to a recipient 
     * @param _blueprintID Blueprint ID
     * @param _quantity Quantity to mint
     * @param _nftRecipient Recipient of minted NFTs
     */
    function _mintQuantity(uint256 _blueprintID, uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprints[_blueprintID].erc721TokenIndex;
        uint64 newCap = blueprints[_blueprintID].capacity;
        for (uint16 i; i < _quantity; i++) {
            require(newCap > 0, "quantity > cap");
            
            _mint(_nftRecipient, newTokenId + i);
            tokenToBlueprintID[newTokenId + i] = _blueprintID;

            bytes32 prefixHash = keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.coinbase,
                    newCap
                )
            );
            emit BlueprintMinted(
                _blueprintID,
                blueprints[_blueprintID].artist,
                _nftRecipient,
                newTokenId + i,
                newCap,
                prefixHash
            );
            --newCap;
        }

        blueprints[_blueprintID].erc721TokenIndex += _quantity;
        blueprints[_blueprintID].capacity = newCap;
    }

    /**
     * @dev Pay for minting NFTs 
     * @param _blueprintID Blueprint ID 
     * @param _quantity Quantity of NFTs to purchase
     * @param _tokenAmount Payment amount provided
     * @param _artist Artist of blueprint
     */
    function _confirmPaymentAmountAndSettleSale(
        uint256 _blueprintID,
        uint32 _quantity,
        uint256 _tokenAmount,
        address _artist
    ) internal {
        address _erc20Token = blueprints[_blueprintID].ERC20Token;
        uint128 _price = blueprints[_blueprintID].price;
        if (_erc20Token == address(0)) {
            require(_tokenAmount == 0, "tokenAmount != 0");
            require(
                msg.value == _quantity * _price,
                "$ != expected"
            );
            _payFeesAndArtist(_blueprintID, _erc20Token, msg.value, _artist);
        } else {
            require(msg.value == 0, "eth value != 0");
            require(
                _tokenAmount == _quantity * _price,
                "$ != expected"
            );

            IERC20(_erc20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            _payFeesAndArtist(_blueprintID, _erc20Token, _tokenAmount, _artist);
        }
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * @dev Create a merkle tree with address: quantity pairs as the leaves.
     *      The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     * @param account Minting account being verified
     * @param quantity Quantity to mint, being verified
     */
    function _leaf(address account, uint256 quantity)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, quantity));
    }

    /**
     * @dev Verify a leaf's inclusion in a merkle tree with its root and corresponding proof
     * @param leaf Leaf to verify
     * @param merkleroot Merkle tree's root
     * @param proof Corresponding proof for leaf
     */
    function _verify(
        bytes32 leaf,
        bytes32 merkleroot,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @dev Update blueprint's token uri
     * @param blueprintID Blueprint ID
     * @param newBaseTokenUri New base token uri to update to
     */
    function updateBlueprintTokenUri(
        uint256 blueprintID,
        string memory newBaseTokenUri
    ) external onlyRole(MINTER_ROLE) isBlueprintPrepared(blueprintID) {
        require(
            !blueprints[blueprintID].tokenUriLocked,
            "locked"
        );

        blueprints[blueprintID].baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(blueprintID, newBaseTokenUri);
    }

    /**
     * @dev Lock blueprint's token uri (from changing)
     * @param blueprintID Blueprint ID
     */ 
    function lockBlueprintTokenUri(uint256 blueprintID)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isBlueprintPrepared(blueprintID)
    {
        require(
            !blueprints[blueprintID].tokenUriLocked,
            "locked"
        );

        blueprints[blueprintID].tokenUriLocked = true;
    }

    /**
     * @dev Return token's uri
     * @param tokenId ID of token to return uri for
     * @return Token uri, constructed by taking base uri of blueprint corresponding to token, and concatenating token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "token dne"
        );

        string memory baseURI = blueprints[tokenToBlueprintID[tokenId]].baseTokenUri;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        tokenId.toString(),
                        "/",
                        "token.json"
                    )
                )
                : "";
    }

    /**
     * @dev Reveal blueprint's seed by emitting public event 
     * @param blueprintID Blueprint ID
     * @param randomSeed Revealed seed 
     */
    function revealBlueprintSeed(uint256 blueprintID, string memory randomSeed)
        external
        onlyRole(MINTER_ROLE)
        isBlueprintPrepared(blueprintID)
    {
        emit BlueprintSeed(blueprintID, randomSeed);
    }

    /**
     * @dev Set the contract-wide recipient of primary sale feess
     * @param _asyncSaleFeesRecipient New async sale fees recipient 
     */
    function setAsyncFeeRecipient(address _asyncSaleFeesRecipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        asyncSaleFeesRecipient = _asyncSaleFeesRecipient;
    }

    /**
     * @dev Change the default percentage of primary sales sent to platform
     * @param _basisPoints New default platform primary fee percentage (in basis points)
     */    
    function changeDefaultPlatformPrimaryFeePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints <= 10000);
        defaultPlatformPrimaryFeePercentage = _basisPoints;
    }

    /**
     * @dev Change the default secondary sale percentage sent to artist and others 
     * @param _basisPoints New default secondary fee percentage (in basis points)
     */    
    function changeDefaultBlueprintSecondarySalePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints + defaultPlatformSecondarySalePercentage <= 10000);
        defaultBlueprintSecondarySalePercentage = _basisPoints;
    }

    /**
     * @dev Change the default secondary sale percentage sent to platform 
     * @param _basisPoints New default secondary fee percentage (in basis points)
     */  
    function changeDefaultPlatformSecondarySalePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _basisPoints + defaultBlueprintSecondarySalePercentage <= 10000
        );
        defaultPlatformSecondarySalePercentage = _basisPoints;
    }

    /**
     * @dev Update contract-wide platform address, and DEFAULT_ADMIN role ownership
     * @param _platform New platform address
     */   
    function updatePlatformAddress(address _platform)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @dev Update contract-wide minter address, and MINTER_ROLE role ownership
     * @param newMinterAddress New minter address
     */ 
    function updateMinterAddress(address newMinterAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, newMinterAddress);

        revokeRole(MINTER_ROLE, minterAddress);
        minterAddress = newMinterAddress;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    /**
     * @dev Pay primary fees owed to primary fee recipients
     * @param _blueprintID Blueprint ID 
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     * @param _artist Artist being paid
     */
    function _payFeesAndArtist(
        uint256 _blueprintID,
        address _erc20Token,
        uint256 _amount,
        address _artist
    ) internal {
        address[] memory _primaryFeeRecipients = getPrimaryFeeRecipients(
            _blueprintID
        );
        uint32[] memory _primaryFeeBPS = getPrimaryFeeBps(_blueprintID);
        uint256 feesPaid;

        for (uint256 i; i < _primaryFeeRecipients.length; i++) {
            uint256 fee = (_amount * _primaryFeeBPS[i])/10000;
            feesPaid = feesPaid + fee;
            _payout(_primaryFeeRecipients[i], _erc20Token, fee);
        }
        if (_amount - feesPaid > 0) {
            _payout(_artist, _erc20Token, (_amount - feesPaid));
        }
    }

    /**
     * @dev Simple payment function to pay an amount of currency to a recipient
     * @param _recipient Recipient of payment 
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     */
    function _payout(
        address _recipient,
        address _erc20Token,
        uint256 _amount
    ) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    /**
     * @dev When a native gas token payment fails, credits are stored so that the would-be recipient can withdraw them later.
     *      Withdraw failed credits for a recipient
     * @param recipient Recipient owed some amount of native gas token   
     */
    function withdrawAllFailedCredits(address payable recipient) external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "!credits");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = recipient.call{value: amount, gas: 20000}(
            ""
        );
        require(successfulWithdraw, "failed");
    }

    /**
     * @dev Get primary fee recipients of a blueprint 
     * @param id Blueprint ID
     */
    function getPrimaryFeeRecipients(uint256 id)
        public
        view
        returns (address[] memory)
    {
        if (blueprints[id].feeRecipientInfo.primaryFeeRecipients.length == 0) {
            address[] memory primaryFeeRecipients = new address[](1);
            primaryFeeRecipients[0] = (asyncSaleFeesRecipient);
            return primaryFeeRecipients;
        } else {
            return blueprints[id].feeRecipientInfo.primaryFeeRecipients;
        }
    }

    /**
     * @dev Get primary fee bps (allocations) of a blueprint 
     * @param id Blueprint ID
     */
    function getPrimaryFeeBps(uint256 id)
        public
        view
        returns (uint32[] memory)
    {
        if (blueprints[id].feeRecipientInfo.primaryFeeBPS.length == 0) {
            uint32[] memory primaryFeeBPS = new uint32[](1);
            primaryFeeBPS[0] = defaultPlatformPrimaryFeePercentage;

            return primaryFeeBPS;
        } else {
            return blueprints[id].feeRecipientInfo.primaryFeeBPS;
        }
    }

    /**
     * @dev Get secondary fee recipients of a token 
     * @param tokenId Token ID
     */
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory feeRecipients = new address[](1);
        feeRecipients[0] = blueprints[tokenToBlueprintID[tokenId]].feeRecipientInfo.royaltyRecipient;
        return feeRecipients;
    }

    /**
     * @dev Get secondary fee bps (allocations) of a token 
     * @param tokenId Token ID
     */
    function getFeeBps(uint256 tokenId)
        public
        view
        override
        returns (uint32[] memory)
    {
        uint32[] memory feeBPS  = new uint32[](1);
        feeBPS[0] = blueprints[tokenToBlueprintID[tokenId]].feeRecipientInfo.totalRoyaltyCutBPS;
        return feeBPS; 
    }

    ////////////////////////////////////
    /// Required function overide //////
    ////////////////////////////////////

    /**
     * @dev Override isApprovedForAll to also let the DEFAULT_ADMIN_ROLE move tokens
     * @param account Account holding tokens being moved
     * @param operator Operator moving tokens
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(account, operator) ||
            hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    /**
     * @dev ERC165 - Validate that the contract supports a interface
     * @param interfaceId ID of interface being validated 
     * @return Returns true if contract supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC165StorageUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(HasSecondarySaleFees).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }
}
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)
/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)
/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)
/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)
/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)
/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)
/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)
/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)
/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

/**
 * @dev Used to deploy and configure CreatorBlueprints contracts in multiple settings
 * @author Ohimire Labs
 */
contract BlueprintsFactory is Ownable { 
    /**
     * @dev Emitted when contract is deployed, exposing Async Art system contracts deployed in the process
     * @param creatorBlueprintsImplementation Address of deployed CreatorBlueprints implementation used in beacon upgradability 
     * @param creatorBlueprintsBeacon Address of deployed beacon tracking CreatorBlueprints implementation
     * @param blueprintV12Implementation Address of deployed global BlueprintV12 implementation 
     * @param blueprintV12Beacon Address of deployed beacon tracking BlueprintV12 implementation
     */
    event FactoryDeployed(
        address creatorBlueprintsImplementation, 
        address creatorBlueprintsBeacon,
        address blueprintV12Implementation,
        address blueprintV12Beacon
    );

    /**
     * @dev Emitted when CreatorBlueprint is deployed
     * @param creatorBlueprint Address of deployed CreatorBlueprints BeaconProxy 
     * @param royaltySplit Address of associated royalty splitter contract
     * @param blueprintPlatformID Platform's identification of blueprint
     */
    event CreatorBlueprintDeployed(
        address indexed creatorBlueprint,
        address indexed royaltySplit,
        string blueprintPlatformID
    );

    /**
     * @dev Emitted when BlueprintV12 is deployed
     * @param blueprintV12 Address of deployed BlueprintV12 BeaconProxy 
     */
    event BlueprintV12Deployed(
        address indexed blueprintV12
    );

    /**
     * @dev Beacon keeping track of current CreatorBlueprint implementation
     */
    address public immutable creatorBlueprintsBeacon; 

    /**
     * @dev Beacon keeping track of current BlueprintV12 implementation
     */
    address public immutable blueprintV12Beacon; 

    /**
     * @dev System royalty manager
     */
    address private immutable _splitMain;

    /**
     * @dev Set of default addresses to be given privileges in each CreatorBlueprint 
     */
    IBlueprintTypes.Admins public defaultCreatorBlueprintsAdmins;

    /**
     * @dev Set of default addresses to be given privileges in each BlueprintV12 
     */
    IBlueprintTypes.Admins public defaultBlueprintV12Admins;

    /**
     * @dev This constructor takes a network from raw to a fully deployed AsyncArt Blueprints system
     * @param creatorBlueprintsBeaconUpgrader Account that can upgrade the CreatorBlueprint implementation 
     * @param globalBlueprintsBeaconUpgrader Account able to upgrade global BlueprintV12 implementation (via beacon)
     * @param creatorBlueprintsMinter Initial default address assigned MINTER_ROLE on CreatorBlueprints instances
     * @param _platform Address given DEFAULT_ADMIN role on BlueprintV12 and set as initial default address assigned DEFAULT_ADMIN role on CreatorBlueprints instances
     * @param splitMain Royalty manager
     * @param factoryOwner Initial owner of this contract 
     */
    constructor(
        address creatorBlueprintsBeaconUpgrader, 
        address globalBlueprintsBeaconUpgrader,
        address globalBlueprintsMinter,
        address creatorBlueprintsMinter,
        address _platform,
        address splitMain,
        address factoryOwner
    ) {
        // deploy CreatorBlueprints implementation and beacon 
        address creatorBlueprintsImplementation = address(new CreatorBlueprints()); 
        address _beacon = address(new UpgradeableBeacon(creatorBlueprintsImplementation)); 
        Ownable(_beacon).transferOwnership(creatorBlueprintsBeaconUpgrader);
        creatorBlueprintsBeacon = _beacon; // extra step, as one cannot read immutable variables in a constructor

        // deploy blueprintV12 implementation and Beacon for it
        address blueprintV12Implementation = address(new BlueprintV12()); 
        address _globalBeacon = address(new UpgradeableBeacon(blueprintV12Implementation)); 
        Ownable(_globalBeacon).transferOwnership(globalBlueprintsBeaconUpgrader); 
        blueprintV12Beacon = _globalBeacon; // extra step as one cannot read immutable variables in a constructor 

        _splitMain = splitMain; 

        // start off with both set of default admins being the same
        defaultCreatorBlueprintsAdmins = IBlueprintTypes.Admins(_platform, creatorBlueprintsMinter, _platform);
        defaultBlueprintV12Admins =  IBlueprintTypes.Admins(_platform, globalBlueprintsMinter, _platform);

        _transferOwnership(factoryOwner);

        emit FactoryDeployed(
            creatorBlueprintsImplementation, 
            _beacon,
            blueprintV12Implementation,
            _globalBeacon          
        );
    }
 
    /**
     * @dev Deploy BlueprintV12 contract only
     * @param _name Name of BlueprintV12 instance
     * @param _symbol Symbol of BlueprintV12 instance
     */
    function deployGlobalBlueprint(
        string calldata _name, 
        string calldata _symbol
    ) external {
        address proxy = address(new BeaconProxy(
            blueprintV12Beacon,
            abi.encodeWithSelector(
                BlueprintV12(address(0)).initialize.selector,
                _name,
                _symbol,
                defaultBlueprintV12Admins,
                _splitMain           
            )
        ));

        emit BlueprintV12Deployed(
            proxy
        ); 
    }

    /**
     * @dev Deploy CreatorBlueprints contract only
     * @param creatorBlueprintsInput Object containing core CreatorBlueprints configuration 
     * @param royaltyCutBPS Total percentage of token purchases taken by royalty split on CreatorBlueprint deployed instance
     * @param split Pre-existing royalty splits contract
     * @param blueprintPlatformID Platform's identification of blueprint
     */
    function deployCreatorBlueprints(
        CreatorBlueprints.CreatorBlueprintsInput calldata creatorBlueprintsInput,
        uint32 royaltyCutBPS,
        address split,
        string calldata blueprintPlatformID
    ) external {
        _deployCreatorBlueprints(
            creatorBlueprintsInput,
            royaltyCutBPS,
            split,
            address(0),
            blueprintPlatformID
        );
    }

    /**
     * @dev Deploy CreatorBlueprints and associated royalty splitter contract 
     * @param creatorBlueprintsInput Object containing core CreatorBlueprints configuration 
     * @param royaltyRecipients Array of royalty recipients to encode into immutable royalty split
     * @param allocations Array of allocations by percentage, given to members in royaltyRecipients 
     * @param royaltyCutBPS Total percentage of token purchases taken by royalty split on CreatorBlueprint deployed instance
     * @param blueprintPlatformID Platform's identification of blueprint
     */
    function deployCreatorBlueprintsAndRoyaltySplitter(
        CreatorBlueprints.CreatorBlueprintsInput calldata creatorBlueprintsInput,
        address[] calldata royaltyRecipients, 
        uint32[] calldata allocations,
        uint32 royaltyCutBPS,
        string calldata blueprintPlatformID
    ) external {
        address split = ISplitMain(_splitMain).createSplit(
            royaltyRecipients, 
            allocations, 
            0, 
            address(0)
        );

        _deployCreatorBlueprints(
            creatorBlueprintsInput, 
            royaltyCutBPS,
            split,
            address(0),
            blueprintPlatformID
        );
    }

    /**
     * @dev Deploy CreatorBlueprints and prepare blueprint on it 
     * @param creatorBlueprintsInput Object containing core CreatorBlueprints configuration 
     * @param blueprintPreparationConfig Object containing values needed to prepare blueprint
     * @param primaryFees Primary fees data (recipients and allocations)
     * @param royaltyCutBPS Total percentage of token purchases taken by royalty split on CreatorBlueprint deployed instance
     * @param split Pre-existing royalty splits contract
     * @param blueprintPlatformID Platform's identification of blueprint
     */
    function deployAndPrepareCreatorBlueprints(
        CreatorBlueprints.CreatorBlueprintsInput calldata creatorBlueprintsInput,
        IBlueprintTypes.BlueprintPreparationConfig calldata blueprintPreparationConfig,
        IBlueprintTypes.PrimaryFees calldata primaryFees,
        uint32 royaltyCutBPS,
        address split,
        string calldata blueprintPlatformID
    ) external {
        address blueprintContract = _deployCreatorBlueprints(
            creatorBlueprintsInput,
            royaltyCutBPS,
            split,
            address(this),
            blueprintPlatformID
        );

        CreatorBlueprints(blueprintContract).prepareBlueprint(blueprintPreparationConfig, primaryFees);

        // renounce role as minter
        IAccessControlUpgradeable(blueprintContract).renounceRole(keccak256("MINTER_ROLE"), address(this));
    }

    /**
     * @dev Deploy CreatorBlueprints, deploy associated royalty splitter contract, and prepare blueprint
     * @param creatorBlueprintsInput Object containing core CreatorBlueprints configuration 
     * @param blueprintPreparationConfig Object containing values needed to prepare blueprint
     * @param primaryFees Primary fees data (recipients and allocations) 
     * @param royaltyRecipients Array of royalty recipients to encode into immutable royalty split
     * @param allocations Array of allocations by percentage, given to members in royaltyRecipients 
     * @param royaltyCutBPS Total percentage of token purchases taken by royalty split on CreatorBlueprint deployed instance
     * @param blueprintPlatformID Platform's identification of blueprint
     */
    function deployRoyaltySplitterAndPrepareCreatorBlueprints(
        CreatorBlueprints.CreatorBlueprintsInput calldata creatorBlueprintsInput,
        IBlueprintTypes.BlueprintPreparationConfig calldata blueprintPreparationConfig,
        IBlueprintTypes.PrimaryFees calldata primaryFees,
        address[] calldata royaltyRecipients, 
        uint32[] calldata allocations,
        uint32 royaltyCutBPS,
        string calldata blueprintPlatformID
    ) external {
        address split = ISplitMain(_splitMain).createSplit(
            royaltyRecipients, 
            allocations, 
            0, 
            address(0)
        );

        address blueprintContract = _deployCreatorBlueprints(
            creatorBlueprintsInput, 
            royaltyCutBPS,
            split,
            address(this),
            blueprintPlatformID
        );

        CreatorBlueprints(blueprintContract).prepareBlueprint(blueprintPreparationConfig, primaryFees);

        // renounce role as minter
        IAccessControlUpgradeable(blueprintContract).renounceRole(keccak256("MINTER_ROLE"), address(this));
    }

    /**
     * @dev Used to predict royalty split address deployed via this factory. Result can be encoded into contract-level metadata before deployment.
     * @param royaltyRecipients Array of royalty recipients to encode into immutable royalty split
     * @param allocations Array of allocations by percentage, given to members in royaltyRecipients
     */
    function predictBlueprintsRoyaltiesSplitAddress(
        address[] calldata royaltyRecipients, 
        uint32[] calldata allocations
    ) external view returns(address) {
        return ISplitMain(_splitMain).predictImmutableSplitAddress(
            royaltyRecipients, 
            allocations, 
            0
        );
    }

    /**
     * @dev Deploys CreatorBlueprints contract 
     * @param creatorBlueprintsInput Object containing core CreatorBlueprints configuration 
     * @param royaltyCutBPS Total percentage of token purchases taken by royalty split on CreatorBlueprint deployed instance
     * @param split Pre-existing royalty splits contract 
     * @param extraMinter Extra account given MINTER_ROLE initially on CreatorBlueprint instance. Expected to be revoked in same transaction, if input is non-zero. 
     * @param blueprintPlatformID Platform's identification of blueprint
     */
    function _deployCreatorBlueprints(
        CreatorBlueprints.CreatorBlueprintsInput calldata creatorBlueprintsInput, 
        uint32 royaltyCutBPS,
        address split,
        address extraMinter,
        string calldata blueprintPlatformID
    ) private returns (address) {
        CreatorBlueprints.RoyaltyParameters memory royaltyParameters = CreatorBlueprints.RoyaltyParameters(split, royaltyCutBPS);
        address creatorBlueprint = address(new BeaconProxy(
            creatorBlueprintsBeacon,
            abi.encodeWithSelector(
                CreatorBlueprints(address(0)).initialize.selector, 
                creatorBlueprintsInput,
                defaultCreatorBlueprintsAdmins,
                royaltyParameters,
                extraMinter
            )
        ));

        emit CreatorBlueprintDeployed(
            creatorBlueprint,
            split,
            blueprintPlatformID
        ); 

        return creatorBlueprint;
    }

    /**
     * @dev Owner-only function to change the default addresses given privileges on CreatorBlueprints instances 
     * @param _newDefaultCreatorBlueprintsAdmins New set of default addresses
     */
    function changeDefaultCreatorBlueprintsAdmins(
        IBlueprintTypes.Admins calldata _newDefaultCreatorBlueprintsAdmins
    ) external onlyOwner {
        require(
            _newDefaultCreatorBlueprintsAdmins.platform != address(0) && 
            _newDefaultCreatorBlueprintsAdmins.asyncSaleFeesRecipient != address(0) && 
            _newDefaultCreatorBlueprintsAdmins.minter != address(0), 
            "Invalid address"
        );
        defaultCreatorBlueprintsAdmins = _newDefaultCreatorBlueprintsAdmins;
    }

    /**
     * @dev Owner-only function to change the default addresses given privileges on BlueprintV12 instances 
     * @param _newDefaultBlueprintV12Admins New set of default addresses
     */
    function changeDefaultBlueprintV12Admins(
        IBlueprintTypes.Admins calldata _newDefaultBlueprintV12Admins
    ) external onlyOwner {
        require(
            _newDefaultBlueprintV12Admins.platform != address(0) && 
            _newDefaultBlueprintV12Admins.asyncSaleFeesRecipient != address(0) && 
            _newDefaultBlueprintV12Admins.minter != address(0), 
            "Invalid address"
        );
        defaultBlueprintV12Admins = _newDefaultBlueprintV12Admins;
    }
}