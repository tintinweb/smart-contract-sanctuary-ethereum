/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
// File: @rarible/royalties/contracts/LibPart.sol



pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: ERC721M.sol


pragma solidity ^0.8.0;







struct TokenData{
    uint8 _boolState; //[slot,slot,slot,slot,slot,slot,_burned,_minted]
    uint16 _tokenIdx;
    uint72 _slot1;
    address _owner;
    uint96 _slot2;
    address _minter;
    uint96 _slot3;
    address _tokenApproval;
}

struct AddressInfo{
    uint8 _boolState; // [slot,slot,slot,slot,slot,slot,ogHolder,owner]
    uint8 _slot2;
    uint8 _freeTicket;
    uint8 _promoTicket;
    uint16 _balance;
    uint16 _minted;
    uint64 _slot3;
    uint128 _og;
}

contract ERC721M is Context, ERC165, IERC721, IERC721Metadata{
    using Address for address;
    using Strings for uint256;

    bytes32 private _name;
    bytes32 private _symbol;
    string internal _tokenBaseURI;

    mapping(uint256 => TokenData) internal _tokenData;
    mapping(address => AddressInfo) internal _addressInfo;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = bytes32(abi.encodePacked(name_));
        _symbol = bytes32(abi.encodePacked(symbol_));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _exists(uint256 _tokenId) public view virtual returns (bool) {
        return ((_tokenData[_tokenId]._boolState << 7) >> 7 ) > 0;
    }

    function _burned(uint256 _tokenId) public view returns(bool){
        return ((_tokenData[_tokenId]._boolState << 6) >> 7 ) > 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "NE");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, "") returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("NI");
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

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenData[tokenId]._owner;
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "NE");
        return _tokenData[tokenId]._tokenApproval;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "0A");
        return _addressInfo[owner]._balance;
    }

    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked(_name));
    }

    function symbol() public view virtual override returns (string memory) {
        return string(abi.encodePacked(_symbol));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NE");
        return !_burned(tokenId) ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return string(abi.encodePacked(_tokenBaseURI));
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "NO");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "NO"
        );
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Forbidden");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NO");
        _transfer(from, to, tokenId);
        _data = "";
        require(_checkOnERC721Received(from, to, tokenId), "Non");
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender,"NO");
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _addressInfo[owner]._balance -= 1;
        _tokenData[tokenId]._boolState += 2;
        _tokenData[tokenId]._owner = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "NO");
        require(to != address(0), "NA");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _addressInfo[from]._balance -= 1;
        _addressInfo[to]._balance += 1;
        _tokenData[tokenId]._owner = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenData[tokenId]._tokenApproval = to;
        emit Approval(_tokenData[tokenId]._owner, to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "NO");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Octanium.sol


pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
//import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";



struct DataPacked {
    uint8 salePhase;
    uint8 maxMinted;
    uint16 minted;
    uint16 currentSupply;
    uint16 totalSupply;
    uint16 promoSupply;
    uint16 splitters;
    uint32 _INTERFACE_ID_ERC2981;
    uint32 _INTERFACE_ID_ROYALTIES;
    uint96 baseConstant;
}

contract Octanium is ERC721M {
    using Strings for uint256;

    uint256 private Cost = 0x000000000000000000b1a2bc2ec500000000000000000000006a94d74f430000; //0.05 eth, 0.03 eth
   
    uint256[] private _tokenIdxtoId;
    
    DataPacked private sData;
    Splitter private splitter;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _splitter
    ) ERC721M(_name, _symbol) {
        if(_splitter != address(0)) splitter = Splitter(_splitter);
        _addressInfo[msg.sender]._boolState = 1;
        sData.salePhase = 0;
        sData.maxMinted = 20;
        sData.minted = 0;
        sData.currentSupply = 0;
        sData.totalSupply = 8000;
        sData.promoSupply = 4000 - 118;
        sData.splitters = 2;
        sData._INTERFACE_ID_ERC2981 = 0x2a55205a;
        sData._INTERFACE_ID_ROYALTIES = 0x44c74bcc;
        sData.baseConstant = 0x000000000000001000000001;
    }

    modifier onlyAdmin() {
        require(isAdmin(), "NO");
        _;
    }

    function createElement(uint256[] memory tokens) public payable {
         address _owner = msg.sender;
         uint256 _msgVal = msg.value;
        require(sData.minted + tokens.length <= sData.totalSupply, "OT");
        require(sData.minted + tokens.length == _tokenIdxtoId.length + tokens.length, "OT");
        require(validPriceValue(tokens, _msgVal, _owner), "IP");

        if(!isAdmin()){
            require(_addressInfo[_owner]._minted <= sData.maxMinted, "OB");
        }
        uint256 _royaltyCount = 0;

        for(uint256 i = 0; i < tokens.length; i++){
            uint256 _tkn = tokens[i]; 
            address _tknOwner = ownerOf(_tkn);
            
            require(validDna(_tkn),"ID");
            require(!_exists(_tkn) && !_burned(_tkn), "Exist");
            require( _tknOwner == _owner || _tknOwner == address(0),"Forbidden");

            if(i == 0){
                _tokenData[_tkn]._owner = _owner;
                _tokenData[_tkn]._minter = _owner;
            }

            _tokenIdxtoId.push(_tkn);
            _royaltyCount += getRoyaltyModel(_tkn);

            emit Transfer(address(0), _owner, _tkn);
            require(_checkOnERC721Received(address(0), _owner, _tkn),"Non");
        }

        if(!isAdmin()){
            consumeTickets(tokens, _owner);
        }
        sData.minted += uint16(tokens.length);
        sData.currentSupply += uint16(tokens.length);
        splitter.addShares(_owner, _royaltyCount);

        _addressInfo[_owner]._minted += uint16(tokens.length);
        _addressInfo[_owner]._balance += uint16(tokens.length);
    }

    function burn(uint256 token) public {
        _burn(token);
        sData.currentSupply--;
    }

    function setSalePhase(uint8 _phase) external onlyAdmin{
        sData.salePhase = _phase;
    }

    function setCost(uint256 _base, uint256 _promo) external onlyAdmin{
        Cost = (_base << 128) + _promo;
    }

    function setTotalSupply(uint16 _supply, bool promo) external onlyAdmin{
        if(promo){
            sData.promoSupply = _supply;
        } else{
            sData.totalSupply = _supply;
        }
        splitter.changeShares(sData.totalSupply, sData.promoSupply);
    }

    function setBaseURI(string memory _newURI) external onlyAdmin{
        _tokenBaseURI = _newURI;
    }

    function setSplitter(address _splitter) external onlyAdmin{
        splitter = Splitter(_splitter);
    }

    function setTickets(address[] calldata _users, uint256 _type) public onlyAdmin {
        for(uint256 i; i < _users.length; i++){
            require(_addressInfo[_users[i]]._balance + _addressInfo[_users[i]]._freeTicket + _addressInfo[_users[i]]._promoTicket + 1 < sData.maxMinted);
            if(_type == 1){
                _addressInfo[_users[i]]._freeTicket++;
            } else{
                 _addressInfo[_users[i]]._promoTicket++;
            }
        }
    }

    function setOG(address[] memory _to, uint256[] memory _tokens) public onlyAdmin{
        require(_to.length == _tokens.length, "Length");

        for(uint256 i = 0; i < _to.length; i++){
            uint256 _currentTkn = _tokens[i];
            require(validDna(_currentTkn));
            address _currentTgt = _to[i];
            require((_addressInfo[_currentTgt]._boolState << 6) >> 7 == 0, "OG");
            require(splitter.isOG(_currentTkn),"NO");

            _addressInfo[_to[i]]._boolState += 2;
            _addressInfo[_to[i]]._og = uint128(_currentTkn);
            _tokenData[_currentTkn]._owner = _currentTgt;
        }
    }

    function isAdmin() internal view returns(bool){
        return isAdmin(msg.sender);
    }

    function isAdmin(address _user) public view returns(bool){
        return ((_addressInfo[_user]._boolState << 7) >> 7) == 1?true:false;
    }

    function consumeTickets(uint256[] memory _tokens, address _user) internal {
        uint256 _freeTicket = 0;
        uint256 _promoTicket = 0;

        for(uint256 i = 0; i <_tokens.length; i++){
            if(!splitter.isOG(_tokens[i])){
                if(sData.salePhase == 2){
                    if(_freeTicket < _addressInfo[_user]._freeTicket){
                        _freeTicket++;
                    } else{
                        if(_promoTicket < _addressInfo[_user]._promoTicket){
                            _promoTicket++;
                        }
                    }
                }
            }
        }

        _addressInfo[_user]._freeTicket -= uint8(_freeTicket);
        _addressInfo[_user]._promoTicket -= uint8(_promoTicket);
    }
    
    function validDna(uint256 _dna) internal view returns(bool){
        return _dna > sData.baseConstant;
    }

    function validPriceValue(uint256[] memory tokens, uint256 _msgVal, address _user) public view returns(bool){
        if(isAdmin(_user)){
            return true;
        } else{
            uint256 totalPrice = 0;
            uint256 _promoVal = getPrice(1);
            uint256 _baseVal = getPrice(2);
            uint256 _freeTicket = _addressInfo[_user]._freeTicket;
            uint256 _promoTicket = _addressInfo[_user]._promoTicket;

            for(uint256 i = 0; i <tokens.length; i++){
                if(!splitter.isOG(tokens[i])){
                    if( sData.salePhase == 1){
                        totalPrice += _promoVal;
                    }else {
                        if(_freeTicket > 0){
                            _freeTicket--;
                        } else{
                            if(_promoTicket > 0){
                                _promoTicket--;
                                totalPrice += _promoVal;
                            } else{
                                totalPrice += _baseVal;
                            }
                        }
                    }
                }
            }
            return _msgVal >= totalPrice;
        }
    }

    function _exists(uint256 _tokenId) public view override returns (bool) {
        uint256 _t = 0;
        for(uint256 i; i < sData.minted; i++){
            if(_tokenIdxtoId[i] == _tokenId){
                _t = 1;
                i = sData.minted;
            }
        }
        return _t > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        if(interfaceId == bytes4(sData._INTERFACE_ID_ROYALTIES)) {
            return true;
        }
        if(interfaceId == bytes4(sData._INTERFACE_ID_ERC2981)) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getRoyaltyModel(uint256 _dna) internal view returns(uint8){
        if(splitter.isOG(_dna)){
            return 3;
        } else{
            if(sData.minted <= sData.promoSupply){
                return 3;
            } else{
                return 2;
            }
        }
    }

    function salePhase() external view returns(uint8){
        return sData.salePhase;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address _lastMinter;

        for (uint256 i = 0; i < sData.minted; i++) {
            uint256 _currentTknId = _tokenIdxtoId[i];
            address _currentTknOwner = _tokenData[_currentTknId]._owner;
            address _currentTknMintr = _tokenData[_currentTknId]._minter;
            if(_tokenIdxtoId[i] == tokenId){
                if(_currentTknOwner != address(0)){
                    _lastMinter = _currentTknOwner;
                }
                i = sData.minted;
            }
            if(_currentTknMintr != address(0)){
                _lastMinter = _currentTknMintr;
            }
        }

        return _lastMinter;
    }

    function getSplitter() external view returns(address){
        return address(splitter);
    }

    function totalSupply() external view returns(uint256){
        return sData.currentSupply;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256){
        require(_index < sData.minted, "OB");
        return _tokenIdxtoId[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(balanceOf(_owner) > _index, "OB");
        uint256 _tknOwnerIdx = 0;
        address _lastMinter;
        for (uint256 i = 0; i < sData.minted; i++) {
            uint256 _currentTknId = _tokenIdxtoId[i];
            address _currentTknOwner = _tokenData[_currentTknId]._owner;
            address _currentTknMintr = _tokenData[_currentTknId]._minter;
            if(_currentTknOwner == _owner){
                if(_tknOwnerIdx == _index){
                    _tknOwnerIdx = _currentTknId;
                    i = sData.totalSupply;
                } else{
                    _tknOwnerIdx++;
                }
            } else{
                if(_currentTknOwner == address(0)){
                    if(_lastMinter == _owner && _exists(_currentTknId) && !_burned(_currentTknId)){
                        if(_tknOwnerIdx == _index){
                            _tknOwnerIdx = _currentTknId;
                            i = sData.totalSupply;
                        } else{
                            _tknOwnerIdx++;
                        }
                    }
                }
            }

            if(_currentTknMintr != address(0)){
                _lastMinter = _currentTknMintr;
            }
        }
        return _tknOwnerIdx;
    }

    function maxSupply() external view returns(uint256){
        return sData.totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "0A");
        return _addressInfo[owner]._balance;
    }

    function getPrice(uint256 _salePhase) public view returns(uint256){
        if(_salePhase == 1){
            return (Cost << 128) >> 128;
        } else {
            return Cost >> 128;
        }
    }

    function ticketOf(address _user) public view returns(uint256,uint256, uint256,bool){
        return(_addressInfo[_user]._freeTicket, _addressInfo[_user]._promoTicket, _addressInfo[_user]._og, (_addressInfo[_user]._boolState << 6) >> 7 == 1);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        if(_exists(_tokenId)){
            return(splitter.getSplitterAddress(), (_salePrice * 500)/10000);
        }

        return (address(0), 0);
    }

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
        require(_exists(id));

        LibPart.Part[] memory _part = new LibPart.Part[](1);
        _part[0].account = splitter.getSplitterAddress();
        _part[0].value = 750;

        return _part;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_tokenBaseURI, "contract"));
    }

    function setAdmin(address _user, bool _add) external onlyAdmin{
        if(_add){
            _addressInfo[_user]._boolState += 1;
        } else{
            _addressInfo[_user]._boolState -= 1;
        }
    }

    function withdrawToken(address payable _stash, address _tokenContract, uint256 _amount) external onlyAdmin {
        IERC20(_tokenContract).transfer(_stash, _amount);
    }

    function withDraw(address payable _stash) external onlyAdmin{
        _stash.transfer(address(this).balance);
    }

    function destroy(address payable _stash) external onlyAdmin{
        selfdestruct(_stash);
    }
}

abstract contract Splitter {
    function isOG(uint256 _dna) external pure virtual returns(bool);
    function addShares(address _user, uint256 _shareType) public virtual;
    function changeShares(uint256 totalSupply, uint256 promoSupply) public virtual;
    function getSplitterAddress() public virtual view returns(address payable);
}