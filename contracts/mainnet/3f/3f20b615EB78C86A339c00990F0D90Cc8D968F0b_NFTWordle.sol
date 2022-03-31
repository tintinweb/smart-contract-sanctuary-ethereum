/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol



pragma solidity ^0.8.0;


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

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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


// File: @openzeppelin/contracts/utils/Address.sol



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
    /*function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }*/

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



// File: @openzeppelin/contracts/utils/Strings.sol



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
    /*function toHexString(uint256 value) internal pure returns (string memory) {
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
    }*/

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    /*function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }*/
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.8.0;












/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    //using EnumerableSet for EnumerableSet.UintSet;
    //using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    //mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    //EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (address => uint256) private tokenBalance;
    mapping (uint256 => address) private tokenOwner;
    mapping (uint256 => bool) private tokenExists;
    uint256 public tokensMinted = 0;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    //mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI = "QmXG2hU11SdZBKLYvJakX8K7EHVnr2PNvuehG38oxyavng";

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        //return _holderTokens[owner].length();
        return tokenBalance[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        //return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
        require(tokenId > 0, "ERC721: owner query for nonexistent token");
        return tokenOwner[tokenId];
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

        //string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        /*if (bytes(base).length == 0) {
            return _tokenURI;
        }*/
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        /*if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }*/
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked("ipfs://", base, "/", tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    /*function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }*/

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        //return _tokenOwners.length();
        //return tokenBalance[];
        return tokensMinted;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    /*function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }*/

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        //return _tokenOwners.contains(tokenId);
        return tokenExists[tokenId];
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        //_holderTokens[to].add(tokenId);
        tokenOwner[tokenId] = to;
        tokenExists[tokenId] = true;

        //_tokenOwners.set(tokenId, to);
        tokenBalance[to] = tokenBalance[to] + 1;
        tokensMinted = tokensMinted + 1;

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        tokenBalance[from]--;
        tokenOwner[tokenId] = to;
        tokenBalance[to]++;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    /*function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }*/

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    /*function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    /*function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }*/
}



pragma solidity ^0.8.0;


abstract contract wordleGame is Ownable, ERC721 {

    struct GameDayStruct {
        uint256 pot;
    }

    struct WithdrawStruct {
        bool nft;
        bool winnings;
    }

    struct GamerStruct {
        uint roundsRemaining;
        uint lastWithdrawDay;
    }

    mapping (address => GamerStruct) public gamers;

    //mapping (uint256 => mapping (address => bool)) public withdrawn;

    //mapping (uint256 => mapping (address => bool)) public allNFTwithdrawn;

    mapping (uint256 => mapping (address => WithdrawStruct)) public withdrawn;

    mapping (uint256 => GameDayStruct) public gameDay;


    mapping (uint256 => uint256[]) public previousHash;
    uint256[] public weights;

    mapping (uint256 => mapping (uint => mapping (address => uint))) public winner;
    mapping (uint256 => mapping (uint256 => uint256)) public winners;
    mapping (uint256 => mapping (uint256 => uint256)) public roundWinners;
    mapping (uint256 => mapping (address => bool)) public firstTry;
    mapping (uint256 => mapping (uint256 => mapping (address => bool))) public recorded;
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public myWins;

    mapping (uint256 => uint256) winnersOfDay;
    mapping (uint256 => uint256) roundsOfDay;

    uint256 public roundCount = 0;

    uint256 public currentRound = 0;
    uint256 public currentDay = 0;

    bool public gameStarted = false;

    uint256 public constant singleRoundPrice = 10000000000000000; //0.01 ETH
    //uint256 public constant fullDayPrice = 180000000000000000; //0.14 ETH

    uint256 public MAX_NWD;

    function newRound(uint32[] memory prevHash, bool resetDay) public onlyOwner {
        if (!gameStarted) {
            gameStarted = true;
        }
        if (resetDay) {
            currentRound = 0;
            previousHash[currentDay] = prevHash;
            currentDay = currentDay + 1;
        }
        currentRound = currentRound + 1;
        roundsOfDay[currentDay] = roundsOfDay[currentDay] + 1;
    }

    function changeWeights(uint256[] memory newWeights) public onlyOwner {
        require(newWeights.length == 5, "E30");
        weights = newWeights;
    }

    function remaining(address checkAddress) public view returns (uint remRounds) {
        if (gamers[checkAddress].roundsRemaining >= 1) {
            return gamers[checkAddress].roundsRemaining;
        } else {
            return 0;
        }
    }

    function buyRounds() public payable {
        require(msg.value >= singleRoundPrice, "E01");
        if (msg.value >= (singleRoundPrice * 24)) {
            gamers[msg.sender].roundsRemaining = gamers[msg.sender].roundsRemaining + 24;
            //if (firstTry[currentDay][msg.sender]) {
            //    gameDay[currentDay].pot = gameDay[currentDay].pot + (singleRoundPrice * 24);
            //}
        } else if (msg.value >= singleRoundPrice) {
            gamers[msg.sender].roundsRemaining = gamers[msg.sender].roundsRemaining + 1;
            //if (firstTry[currentDay][msg.sender]) {
            //    gameDay[currentDay].pot = gameDay[currentDay].pot + singleRoundPrice;
            //}
        }
    }

    function buyAndRecordWin(uint32 guessHash2) public payable {
        uint256 guessHash = guessHash2;
        require(gameStarted, "E90");
        require(msg.value >= singleRoundPrice, "E01");

        gamers[msg.sender].roundsRemaining = gamers[msg.sender].roundsRemaining + 1;

        require(!recorded[currentDay][currentRound][msg.sender], "E91");

        winner[guessHash][currentDay][msg.sender] = winner[guessHash][currentDay][msg.sender] + 1;
        winners[guessHash][currentDay] = winners[guessHash][currentDay] + 1;
        roundWinners[currentDay][currentRound] = roundWinners[currentDay][currentRound] + 1;
        winnersOfDay[currentDay] = winnersOfDay[currentDay] + 1;
        gamers[msg.sender].roundsRemaining = gamers[msg.sender].roundsRemaining - 1;
        recorded[currentDay][currentRound][msg.sender] = true;
        gameDay[currentDay].pot = gameDay[currentDay].pot + singleRoundPrice;
    }

    function recordWin(uint32 guessHash2) public {
        uint256 guessHash = guessHash2;
        require(gameStarted, "E90");
        require(gamers[msg.sender].roundsRemaining > 0, "E17");

        require(!recorded[currentDay][currentRound][msg.sender], "E91");

        winner[guessHash][currentDay][msg.sender] = winner[guessHash][currentDay][msg.sender] + 1;
        winners[guessHash][currentDay] = winners[guessHash][currentDay] + 1;
        roundWinners[currentDay][currentRound] = roundWinners[currentDay][currentRound] + 1;
        winnersOfDay[currentDay] = winnersOfDay[currentDay] + 1;
        gamers[msg.sender].roundsRemaining = gamers[msg.sender].roundsRemaining - 1;
        recorded[currentDay][currentRound][msg.sender] = true;
        gameDay[currentDay].pot = gameDay[currentDay].pot + singleRoundPrice;
    }

    function earnings(uint8 isNFT, address whothis) public view returns (uint256 myBalance) {
        require(gameStarted, "E90");

        uint256 myAmount = 0;

        require(currentDay > 1, "E05");

        uint256 tempDay = gamers[whothis].lastWithdrawDay + 1;

        uint256 totalWeight;
        for (uint256 counter = 0; counter < weights.length; counter++) {
            totalWeight = totalWeight + weights[counter];
        }

        for (uint256 withdrawDay = tempDay; withdrawDay < currentDay; withdrawDay++) {

            if (isNFT == 1) {
                require(!withdrawn[withdrawDay][whothis].nft, "E06");
                require(balanceOf(whothis) > 0, "E95");
                uint256 tokenCount = balanceOf(whothis);
                require(tokenCount > 0, "E07");
                uint256 supply = totalSupply();
                myAmount = tokenCount * ((gameDay[withdrawDay].pot * 30) / 100) / supply;
            } else {
                //63%
                for (uint256 counter = 0; counter < previousHash[withdrawDay].length; counter++) {
                    if (
                            winner[previousHash[withdrawDay][counter]][withdrawDay][whothis] > 0 &&
                            !withdrawn[withdrawDay][whothis].winnings
                        ) {
                        myAmount = myAmount + 
                            (
                                winner[previousHash[withdrawDay][counter]][withdrawDay][whothis]
                                *
                                (
                                    weights[counter] *
                                    ((gameDay[withdrawDay].pot * 63) / 100)
                                    / totalWeight
                                )
                                /
                                winners[previousHash[withdrawDay][counter]][withdrawDay]
                            );
                    }
                }
            }
        }

        return myAmount;
    }

    function withdrawEarnings(uint8 isNFT, address whothis) public returns (uint256 myBalance) {
        require(gameStarted, "E90");
        require(whothis == msg.sender, "E97");
        uint256 tempDay = gamers[msg.sender].lastWithdrawDay + 1;

        if (currentDay == tempDay) {
            return 0;
        }

        uint256 myAmount = earnings(isNFT, whothis);

        if (myAmount <= 0) {
            return 0;
        }

        for (uint256 withdrawDay = tempDay; withdrawDay < currentDay; withdrawDay++) {
            if (isNFT == 1) {
                withdrawn[withdrawDay][msg.sender].nft = true;
            } else {
                withdrawn[withdrawDay][msg.sender].winnings = true;
            }
        }

        gamers[msg.sender].lastWithdrawDay = currentDay - 1;

        payable(msg.sender).transfer(myAmount);
        return myAmount;
    }

    
}


pragma solidity ^0.8.0;

/*
 * @title NFTWordle contract
 */
contract NFTWordle is wordleGame {

    uint256 public NWDPrice = 50000000000000000; //0.05 ETH
    //uint256 public constant NWDWhitelistPrice = 25000000000000000; //0.03 ETH

    uint256 public constant maxNWDPurchase = 10;

    uint256 public constant maxWLPurchase = 2;

    bool public saleIsActive = false;

    bool public wlState = false;

    bool public ogState = false;

    bool public noOGState = false;

    struct OgStruct {
        uint8 ogs;
        uint8 wls;
    }

    uint16 public freeMints = 0;

    mapping (address => OgStruct) public addies;

    uint256 lastGRWithdraw;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply) ERC721(name, symbol) {
        MAX_NWD = maxNftSupply;
        weights = [10, 8, 4, 2, 1];
    }

    function gameWallet() public view returns (uint256 balance) {
        //uint256 balance = address(this).balance;

        uint256 tempDay = lastGRWithdraw + 1;

        if (currentDay == tempDay) {
            return 0;
        }

        uint256 totalAmount;

        for (uint256 withdrawDay = tempDay; withdrawDay < currentDay; withdrawDay++) {
            totalAmount = totalAmount + (gameDay[withdrawDay].pot * 7) / 100;
        }

        return totalAmount;
    }

    function potBalance() public view returns (uint256 balance) {
        //uint256 balance = address(this).balance;

        uint256 tempDay = lastGRWithdraw + 1;

        if (currentDay == tempDay) {
            return 0;
        }

        uint256 totalAmount;

        for (uint256 withdrawDay = tempDay; withdrawDay < currentDay; withdrawDay++) {
            totalAmount = totalAmount + gameDay[withdrawDay].pot;
        }

        return totalAmount;
    }

    function withdraw(uint256 amount) public onlyOwner {
        lastGRWithdraw = currentDay - 1;
        payable(msg.sender).transfer(amount);
    }

    function updateMintPrice(uint256 newPrice) public onlyOwner {
        NWDPrice = newPrice;
    }

    /**
     * Set some NWD aside
     */
    function reserveNWD() public onlyOwner {        
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 1; i < 10; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipState(uint8 sale) public onlyOwner {
        if (sale == 1) {
            saleIsActive = !saleIsActive;
            if (saleIsActive) {
                wlState = false;
            }
        }
        if (sale == 2) {
            wlState = !wlState;
        }
        if (sale == 3) {
            ogState = !ogState;
        }
        if (sale == 4) {
            noOGState = !noOGState;
        }
    }

    function addAddresses(bool isOg, address[] memory addressList) public onlyOwner {
        for (uint i = 0; i < addressList.length; i++) {
            if (isOg) {
                addies[addressList[i]].ogs = 1;
                addies[addressList[i]].wls = 1;
            } else {
                addies[addressList[i]].wls = 1;
            }
        }
    }

    /**
     * Mint free for OG
     */
    function freeMint() public payable {        
        uint256 supply = totalSupply();
        require(ogState, "E20");
        require(addies[msg.sender].ogs == 1, "E21");
        require(addies[msg.sender].ogs != 1, "E55");
        require(supply < MAX_NWD, "E23");
        addies[msg.sender].ogs = 2;
        freeMints = freeMints + 1;
        _safeMint(msg.sender, supply + 1);
    }

    /**
    * Mints NWD
    */
    function mintNWD(uint8 numberOfTokens) public payable {
        uint256 delta = 0;
        if (!noOGState) {
            delta = 500 - freeMints;
        }
        uint256 supply = totalSupply();
        require(numberOfTokens <= maxNWDPurchase, "E11");
        require((supply + numberOfTokens) <= (MAX_NWD - delta), "E12");
        if (addies[msg.sender].wls > 0 && addies[msg.sender].wls < (maxWLPurchase + 1)) {
            require(wlState, "E30");
            require(numberOfTokens <= (maxWLPurchase - (addies[msg.sender].wls - 1)), "E13");
            //require(NWDWhitelistPrice * numberOfTokens <= msg.value, "E14");
            require(NWDPrice * numberOfTokens <= msg.value, "E15");
            addies[msg.sender].wls = addies[msg.sender].wls + numberOfTokens;
        } else {
            require(saleIsActive, "E10");
            require(NWDPrice * numberOfTokens <= msg.value, "E15");
        }
        
        for(uint256 i = 1; i <= numberOfTokens; i++) {
            if (supply < (MAX_NWD - delta)) {
                _safeMint(msg.sender, supply + i);
            }
        }
    }



}