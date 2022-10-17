/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// File: contracts/test2/IHelper.sol


pragma solidity 0.8.4;

interface IHelper{
    struct NFTData{
        string background;
        string hat;
        string jacket;
        string hair;
        string nose;
        string glass;
        string ear;
    }
    function getTokenURI(uint256 tokenId,string memory baseURI,NFTData memory data) external pure returns(string memory);
}
// File: contracts/test2/StorageV2.sol


pragma solidity 0.8.4;

contract StorageV2{
    //Intergers
    uint256 public tokenIdCounter;
    uint256 public getPrice = 0.0000005 ether; // Getters
    uint256 public getPreSalePrice = 0.0000004 ether;

    //sizes of trait
    uint256 sHat = 14;
    uint256 sJacket = 14;
    uint256 sHair = 13;
    uint256 sNose = 8;
    uint256 sGlass = 8;
    uint256 sEar = 8;
    //Bytes32
    bytes32 internal rootHash;
    bytes32 internal freeRootHash;
    //Address
    address internal owner;
    address public getManager;
    address internal helper;
    address payable internal community;
    address payable internal developer;
    //Constant 
    uint256 public maxSupply = 1111;
    //Booleans
    bool public isMintingPause;
    bool public isFreeMintingPaused;
    bool public isWhitelistMintingPause;
    bool public isRevealed;
    //Strings
    // string internal baseURI = "http://3.110.231.144:5000/knowlyets/";
    string internal baseURI = "http://0.0.0.0:5000/knowlyets/";
    string internal revealURI = "";
    
    //Events
    event MintKnowlytes(uint256 indexed tokenId,uint256 bg,uint256 hat,uint256 jacket,uint256 hair,uint256 nose,uint256 glass,uint256 ear,uint256 name);
    event ChangeTrait(uint256 indexed tokenId,bytes32 indexed data);
    //Modifiers
    modifier onlyOwner{
        _onlyOwner();
        _;
    }
    //Structs
    struct TraitValue{
        uint256 value;
        bool isFreezed;
    }

    struct Traits{
      TraitValue Hat;
      TraitValue Jacket;
      TraitValue Hair;
      TraitValue Nose;
      TraitValue Glass;
      TraitValue Ear;
      TraitValue Background;
      uint256 Name;
    }

    struct TokenMetaData{
        uint256 tokenId;
        uint256 changedMonth;
        bytes32 hashedProof;
        Traits currentDetails;
        bool haveChanged;
    }


    //Mappings
    mapping(uint256 => string) internal hatMap;
    mapping(uint256 => string) internal jacketMap;
    mapping(uint256 => string) internal hairMap;
    mapping(uint256 => string) internal noseMap;
    mapping(uint256 => string) internal glassMap;
    mapping(uint256 => string) internal earMap;
    mapping(uint256 => string) internal backgroundMap;
    mapping (uint256 => string) internal nameMap;




    // Traits Freezed Mapping
    mapping(uint256 => bool) internal hatFreezedMap;
    mapping(uint256 => bool) internal jacketFreezedMap;
    mapping(uint256 => bool) internal hairFreezedMap;
    mapping(uint256 => bool) internal noseFreezedMap;
    mapping(uint256 => bool) internal glassFreezedMap;
    mapping(uint256 => bool) internal earFreezedMap;


    //Traits Details
    mapping(uint256 => TokenMetaData) public getNFTDetails;
    mapping(uint256 => mapping(uint256 => uint256)) internal traitCounter;

    //Functions
    function _onlyOwner() private view{
        require(msg.sender == owner,"only Owner");
    }
    function Freceive() public payable {
        uint256 share = msg.value/2;
        community.transfer(share);
        developer.transfer(share);
    }  
}
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/test2/KnowlytesV2.sol

pragma solidity 0.8.4;




// import "hardhat/console.sol";

contract KnowlytesV2 is StorageV2, ERC721 {
    constructor(address _helper,address payable _community,address payable _dev, bytes32 _rootHash, bytes32 _freeRoot)
    // constructor(address _helper,address payable _community,address payable _dev)
        ERC721("Knowlytes", "$KNOW")
    {
        helper = _helper;
        community = _community; //contract- 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
        developer = _dev;
        rootHash = _rootHash; // 0xde03d9de9013a0fecf26e583cda21381fa06a4f846d565ab1c544f24297dde99;
        freeRootHash = _freeRoot; // 0x8017f4981ac06bef74f31af086e4804767c8f0238d3ffa1f798f601b5ed14f2b;
        owner = msg.sender;
        initMapping();
    }
    
    //[[6],[13],[],[],[6,7],[]]   [[1],[3],[],[],[1],[]]
    function check() private{
        tokenIdCounter++;
        require(tokenIdCounter <= maxSupply,"AM");
        // console.log("1");
        updateNFTDetails(tokenIdCounter);
    }
    
    //Mapping for bound the address
    mapping(address => bool) private bound;

    //Minting Knowlytes Functions
    function mintKnowlytes() external payable{
        require(isMintingPause, "P");
        // if (msg.sender != owner) {
        require(msg.value >= getPrice, "WA");
        check();
        Freceive();
    }
    function freemintKnowlytes(bytes32[] calldata proof) external payable{
        require(!bound[msg.sender],"N");
        (bool success, ) = helper.delegatecall(
            abi.encodeWithSignature("isFreeListedAddress(bytes32[])", proof)
        );
        require(success, "F");
        check();
    }

    function mintKnowlytesWhiteList(bytes32[] calldata proof) external payable{
        require(isWhitelistMintingPause, "WMP");
        require(!bound[msg.sender],"N");
        require(msg.value >= getPreSalePrice, "WA");
        (bool success, ) = helper.delegatecall(
            abi.encodeWithSignature("isWhiteListedAddress(bytes32[])", proof)
        );
        require(success, "F");
        check();
        Freceive();
    }

    function updateBatchTraitTypes(
        uint256[] calldata tId,
        uint256[] calldata t,
        uint256[] calldata value
    ) external {
        (bool executed, ) = helper.delegatecall(
            abi.encodeWithSignature(
                "updateBatchTraitType(uint256[],uint256[],uint256[])",
                tId,
                t,
                value
            )
        );
        require(executed, "UF");
    }

    function changeTraits(uint256 tokenId, bytes32 data) external {
        require(ownerOf(tokenId) == msg.sender, "NT");
        (bool success, ) = helper.delegatecall(
            abi.encodeWithSignature(
                "changeTrait(uint256,bytes32)",
                tokenId,
                data
            )
        );
        require(success, "CF");
    }

    function freezeValues(
        uint256[][6] calldata min,
        uint256[][6] calldata totalId
    ) external {
        (bool success, ) = helper.delegatecall(
            abi.encodeWithSignature(
                "freezeValues(uint256[][6],uint256[][6])",
                min,
                totalId
            )
        );
        require(success, "FVF");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "NT");
        TokenMetaData memory nft = getNFTDetails[tokenId];
        IHelper.NFTData memory nftData;
        nftData.background = backgroundMap[nft.currentDetails.Background.value];
        nftData.hat = hatMap[nft.currentDetails.Hat.value];
        nftData.jacket = jacketMap[nft.currentDetails.Jacket.value];
        nftData.hair = hairMap[nft.currentDetails.Hair.value];
        nftData.nose = noseMap[nft.currentDetails.Nose.value];
        nftData.glass = glassMap[nft.currentDetails.Glass.value];
        nftData.ear = earMap[nft.currentDetails.Ear.value];
        if (isRevealed) {
            string memory URI = IHelper(helper).getTokenURI(
                tokenId,
                baseURI,
                nftData
            );
            return URI;
        }
        return revealURI;
    }

    //Public Traits Functions
    function getHatValue(uint256 _type) public view returns (string memory) {
        return hatMap[_type];
    }

    function getJacketValue(uint256 _type) public view returns (string memory) {
        return jacketMap[_type];
    }

    function getHairValue(uint256 _type) public view returns (string memory) {
        return hairMap[_type];
    }

    function getNoseValue(uint256 _type) public view returns (string memory) {
        return noseMap[_type];
    }

    function getGlassValue(uint256 _type) public view returns (string memory) {
        return glassMap[_type];
    }

    function getEarValue(uint256 _type) public view returns (string memory) {
        return earMap[_type];
    }

    function getBackgroundValue(uint256 _type)
        public
        view
        returns (string memory)
    {
        return backgroundMap[_type];
    }

    //Public Traits Booleans
    function isHatFreezed(uint256 _type) public view returns (bool) {
        return hatFreezedMap[_type];
    }

    function isJacketFreezed(uint256 _type) public view returns (bool) {
        return jacketFreezedMap[_type];
    }

    function isHairFreezed(uint256 _type) public view returns (bool) {
        return hairFreezedMap[_type];
    }

    function isNoseFreezed(uint256 _type) public view returns (bool) {
        return noseFreezedMap[_type];
    }

    function isGlassFreezed(uint _type) public view returns (bool) {
        return glassFreezedMap[_type];
    }

    function isEarFreezed(uint _type) public view returns (bool) {
        return earFreezedMap[_type];
    }

    //Toggle Functions
    function toggleMinting() external onlyOwner {
        isMintingPause = !isMintingPause;
    }
    function toggleFreeMinting() external onlyOwner {
        isFreeMintingPaused = !isFreeMintingPaused;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function toggleWhiteListMinting() external onlyOwner {
        isWhitelistMintingPause = !isWhitelistMintingPause;
    }

    // Setters Functions
    function setgetPrice(uint256 _newgetPrice) external onlyOwner {
        getPrice = _newgetPrice;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setRevealURI(string calldata _newURI) external onlyOwner {
        revealURI = _newURI;
    }

    function setManager(address _newManager) external onlyOwner {
        getManager = _newManager;
    }
    function setSupply(uint256 supply) external onlyOwner {
        maxSupply = maxSupply+supply;
    }

    function setTraitvalues(uint256 i, uint256 key, string calldata value) external onlyOwner {
        if (i == 1) {
            hatMap[key] = value;
            sHat = sHat+1;
        }
        else if (i == 2) {
            jacketMap[key] = value;
            sJacket = sJacket+1;
        }
        else if (i == 3) {
            hairMap[key] = value;
            sHair = sHair+1;
        }
        else if (i == 4) {

            noseMap[key] = value;
            sNose = sNose+1;
        }
        else if (i == 5) {
            glassMap[key] = value;
            sGlass = sGlass+1;
        }
        else if (i == 6) {
            earMap[key] = value;
            sEar = sEar+1;
        }
    }

    function setHashroot(bytes32 _newRoot) external onlyOwner {
        rootHash = _newRoot;
    }
    
    function setFreeHashroot(bytes32 _newRoot) external onlyOwner {
        freeRootHash = _newRoot;
    }

    function initMapping() private {
        // hatMap[1] = "Bowler";
        // hatMap[2] = "Wizard";
        // hatMap[3] = "Detective";
        // hatMap[4] = "Chef";
        // hatMap[5] = "Woolhat";
        // hatMap[6] = "Sombrero";
        // hatMap[7] = "Reggae";
        // hatMap[8] = "Witch";
        // hatMap[9] = "Fedor";
        // hatMap[10] = "Drill Instructor";
        // hatMap[11] = "Troops Mask";
        // hatMap[12] = "Troops Mask2";
        // hatMap[13] = "Journalist";
        // hatMap[14] = "Top Hat";
        // jacketMap[1] = "Winter Jacket";
        // jacketMap[2] = "Futura";
        // jacketMap[3] = "Bathrobe";
        // jacketMap[4] = "Suit";
        // jacketMap[5] = "Lather Jacket";
        // jacketMap[6] = "Rain Coat";
        // jacketMap[7] = "Concierge";
        // jacketMap[8] = "Coat";
        // jacketMap[9] = "Apprentice";
        // jacketMap[10] = "Casual Jacket";
        // jacketMap[11] = "Casual Jacket2";
        // jacketMap[12] = "Lab Jacket";
        // jacketMap[13] = "Jonny";
        // jacketMap[14] = "Lincoin";
        // hairMap[1] = "Bibical Beard";
        // hairMap[2] = "Midnight Lincoln";
        // hairMap[3] = "Sensi";
        // hairMap[4] = "Small Goatie";
        // hairMap[5] = "Pirat";
        // hairMap[6] = "Guru";
        // hairMap[7] = "Full Beard";
        // hairMap[8] = "Wlrus";
        // hairMap[9] = "Fu'manchu";
        // hairMap[10] = "Horseshoe";
        // hairMap[11] = "Zappa";
        // hairMap[12] = "Hungarian";
        // hairMap[13] = "Politician";
        // noseMap[1] = "Snub";
        // noseMap[2] = "Pointed";
        // noseMap[3] = "Grecian";
        // noseMap[4] = "Droopy";
        // noseMap[5] = "Flat";
        // noseMap[6] = "Bulbous";
        // noseMap[7] = "Roman";
        // noseMap[8] = "Snub";
        // glassMap[1] = "Pilot";
        // glassMap[2] = "Agent";
        // glassMap[3] = "Anarchist";
        // glassMap[4] = "Journalist";
        // glassMap[5] = "Le Professeur";
        // glassMap[6] = "Con Man";
        // glassMap[7] = "80's";
        // glassMap[8] = "Presidential";
        // earMap[1] = "Squar Ear";
        // earMap[2] = "Pointer Ear";
        // earMap[3] = "Narrow Ear";
        // earMap[4] = "Sticking Out";
        // earMap[5] = "Free Lobe";
        // earMap[6] = "Attached Lobe";
        // earMap[7] = "Broad Lobe";
        // earMap[8] = "Symetrical Ear";
        // backgroundMap[1] = "Blue";
        // backgroundMap[2] = "Confrence";
        // backgroundMap[3] = "Construction";
        // backgroundMap[4] = "Hospital";
        // backgroundMap[5] = "Restaurant";
        // backgroundMap[6] = "Yellow";
        // backgroundMap[7] = "Green";
        hatMap[1] = "Hat1";
        hatMap[2] = "Hat2";
        hatMap[3] = "Hat3";
        hatMap[4] = "Hat4";
        hatMap[5] = "Hat5";
        hatMap[6] = "Hat6";
        hatMap[7] = "Hat7";
        hatMap[8] = "Hat8";
        hatMap[9] = "Hat9";
        hatMap[10] = "Hat10";
        hatMap[11] = "Hat11";
        hatMap[12] = "Hat12";
        hatMap[13] = "Hat13";
        hatMap[14] = "Hat14";
        jacketMap[1] = "Jacket1";
        jacketMap[2] = "Jacket2";
        jacketMap[3] = "Jacket3";
        jacketMap[4] = "Jacket4";
        jacketMap[5] = "Jacket5";
        jacketMap[6] = "Jacket6";
        jacketMap[7] = "Jacket7";
        jacketMap[8] = "Jacket8";
        jacketMap[9] = "Jacket9";
        jacketMap[10] = "Jacket10";
        jacketMap[11] = "Jacket11";
        jacketMap[12] = "Jacket12";
        jacketMap[13] = "Jacket13";
        jacketMap[14] = "Jacket14";
        hairMap[1] = "Hair1";
        hairMap[2] = "Hair2";
        hairMap[3] = "Hair3";
        hairMap[4] = "Hair4";
        hairMap[5] = "Hair5";
        hairMap[6] = "Hair6";
        hairMap[7] = "Hair7";
        hairMap[8] = "Hair8";
        hairMap[9] = "Hair9";
        hairMap[10] = "Hair10";
        hairMap[11] = "Hair11";
        hairMap[12] = "Hair12";
        hairMap[13] = "Hair13";
        noseMap[1] = "Nose1";
        noseMap[2] = "Nose2";
        noseMap[3] = "Nose3";
        noseMap[4] = "Nose4";
        noseMap[5] = "Nose5";
        noseMap[6] = "Nose6";
        noseMap[7] = "Nose7";
        noseMap[8] = "Nose8";
        glassMap[1] = "Glass1";
        glassMap[2] = "Glass2";
        glassMap[3] = "Glass3";
        glassMap[4] = "Glass4";
        glassMap[5] = "Glass5";
        glassMap[6] = "Glass6";
        glassMap[7] = "Glass7";
        glassMap[8] = "Glass8";
        earMap[1] = "Ear1";
        earMap[2] = "Ear2";
        earMap[3] = "Ear3";
        earMap[4] = "Ear4";
        earMap[5] = "Ear5";
        earMap[6] = "Ear6";
        earMap[7] = "Ear7";
        earMap[8] = "Ear8";
        backgroundMap[1] = "Blue";
        backgroundMap[2] = "Confrence";
        backgroundMap[3] = "Construction";
        backgroundMap[4] = "Hospital";
        backgroundMap[5] = "Restaurant";
        backgroundMap[6] = "Yellow";
        backgroundMap[7] = "Green";
        nameMap[1] = "Paul";
        nameMap[2] = "Ben";
        nameMap[3] = "Leon";
        nameMap[4] = "Finn";
        nameMap[5] = "Elias";
        nameMap[6] = "Jonas";
        nameMap[7] = "Luis";
        nameMap[8] = "Noah";
        nameMap[9] = "Felix";
        nameMap[10] = "Lukas";
        nameMap[11] = "Jurgen";
        nameMap[12] = "Karl";
        nameMap[13] = "Stefan";
        nameMap[14] = "Walter";
        nameMap[15] = "Uwe";
        nameMap[16] = "Hans";
        nameMap[17] = "Klaus";
        nameMap[18] = "Emma";
        nameMap[19] = "Mia";
        nameMap[20] = "Hannah";
        nameMap[21] = "Emilia";
        nameMap[22] = "Sofia";
        nameMap[23] = "Lina";
        nameMap[24] = "Anna";
        nameMap[25] = "Mila";
        nameMap[26] = "Lea";
        nameMap[27] = "Ella";
        nameMap[28] = "Ursula";
        nameMap[29] = "Christina";
        nameMap[30] = "Ilse";
        nameMap[31] = "Ingrid";
        nameMap[32] = "Petra";
        nameMap[33] = "Monika";
        nameMap[34] = "Gisela";
        nameMap[35] = "Susanne";
        nameMap[36] = "Baron";
        nameMap[37] = "Brenner";
        nameMap[38] = "Bronson";
        nameMap[39] = "Christoph";
        nameMap[40] = "Conra";
        nameMap[41] = "Corrado";
        nameMap[42] = "Davi";
        nameMap[43] = "Delmar";
        nameMap[44] = "Derek";
        nameMap[45] = "Edga";
        nameMap[46] = "Egelbert";
        nameMap[47] = "Egon";
        nameMap[48] = "Elias";
        nameMap[49] = "Fedde";
        nameMap[50] = "Franz";
        nameMap[51] = "Frederic";
        nameMap[52] = "Geoffrey";
        nameMap[53] = "Godfrey";
        nameMap[54] = "Gunther";
        nameMap[55] = "Hans";
        nameMap[56] = "Hedwig";
        nameMap[57] = "Henry";
        nameMap[58] = "Hulbart";
        nameMap[59] = "Kaiser";
        nameMap[60] = "Kurtis";
        nameMap[61] = "Leon";
        nameMap[62] = "Leopol";
        nameMap[63] = "Louis";
        nameMap[64] = "Marcus";
        nameMap[65] = "Martell";
        nameMap[66] = "Mayne";
        nameMap[67] = "Nicko";
        nameMap[68] = "Nikolaus";
        nameMap[69] = "Noa";
        nameMap[70] = "Odie";
        nameMap[71] = "Raymond";
        nameMap[72] = "Robert";
        nameMap[73] = "Roderick";
        nameMap[74] = "Ryker";
        nameMap[75] = "Truman";
        nameMap[76] = "William";
        nameMap[77] = "Adali";
        nameMap[78] = "Adaleigh";
        nameMap[79] = "Adellene";
        nameMap[80] = "Adelredu";
        nameMap[81] = "Addle";
        nameMap[82] = "Adette";
        nameMap[83] = "Agatha";
        nameMap[84] = "Ail";
        nameMap[85] = "Amalia";
        nameMap[86] = "Amara";
        nameMap[87] = "Bernadine";
        nameMap[88] = "Carri";
        nameMap[89] = "Harry";
        nameMap[90] = "Ronald";
        nameMap[91] = "Harmoinee";
        nameMap[92] = "Ginnie";
        nameMap[93] = "Rubius";
        nameMap[94] = "Serius";
        nameMap[95] = "Albus";
        nameMap[96] = "Dadli";
        nameMap[97] = "Flinch";
        nameMap[98] = "Navil";
        nameMap[99] = "James";
        nameMap[100] = "Lilly";
        nameMap[101] = "Melfoy";
        nameMap[102] = "Tony";
        nameMap[103] = "Natasha";
        nameMap[104] = "Mark";
        nameMap[105] = "Albert";
        nameMap[106] = "Isaac";
        nameMap[107] = "Sedrick";
        nameMap[108] = "Tom";
        nameMap[109] = "George";
        nameMap[110] = "Fred";
        nameMap[111] = "Paumfri";
    }

    function updateNFTDetails(uint256 tokenId) private {
        // console.log("2");
        (bool success, ) = helper.delegatecall(abi.encodeWithSignature("updateNFTDetail(uint256)", tokenId));
        require(success, "Not Updated");
        _safeMint(msg.sender, tokenId);
    }
    // function updateNFTDetails(uint256 tokenId) private {
    //     StorageV2.TokenMetaData storage nft = StorageV2.nftDetails[tokenId];
    //     nft.tokenId = tokenId;
    //     uint256 hat = nft.currentDetails.Hat.value = uint256(
    //         generateRandom(msg.sender, sHat)
    //     );
    //     uint256 jacket = nft.currentDetails.Jacket.value = uint256(
    //         generateRandom(msg.sender, sJacket)
    //     );
    //     uint256 hair = nft.currentDetails.Hair.value = uint256(
    //         generateRandom(msg.sender, sHair)
    //     );
    //     uint256 nose = nft.currentDetails.Nose.value = uint256(
    //         generateRandom(msg.sender, sNose)
    //     );
    //     uint256 glass = nft.currentDetails.Glass.value = uint256(
    //         generateRandom(msg.sender, sGlass)
    //     );
    //     uint256 ear = nft.currentDetails.Ear.value = uint256(
    //         generateRandom(msg.sender, sEar)
    //     );
    //     uint256 bg = nft.currentDetails.Background.value = uint256(
    //         generateRandom(msg.sender, 7)
    //     );
    //     uint256 name = nft.currentDetails.Name.value = uint256(
    //         generateRandom(msg.sender, 100)
    //     );
    //     updateTraitCounter(hat, jacket, hair, nose, glass, ear);
    //     _safeMint(msg.sender, tokenId);
    //     emit MintKnowlytes(tokenId, bg, hat, jacket, hair, nose, glass, ear, name);
    // }


    // function updateTraitCounter(
    //     uint256 hat,
    //     uint256 jacket,
    //     uint256 hair,
    //     uint256 nose,
    //     uint256 glass,
    //     uint256 ear
    // ) private {
        
    //     StorageV2.traitCounter[1][hat] += 1;
    //     StorageV2.traitCounter[2][jacket] += 1;
    //     StorageV2.traitCounter[3][hair] += 1;
    //     StorageV2.traitCounter[4][nose] += 1;
    //     StorageV2.traitCounter[5][glass] += 1;
    //     StorageV2.traitCounter[6][ear] += 1;
    // }

    // function generateRandom(address _account, uint256 range)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     uint256 startToken = 0;
    //     uint256 random = uint256(
    //         keccak256(
    //             abi.encodePacked(
    //                 block.timestamp,
    //                 _account,
    //                 block.difficulty,
    //                 startToken
    //             )
    //         )
    //     ) % range;
    //     if (random == 0) {
    //         revert();
    //     }
    //     return random;
    // }
}