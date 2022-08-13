/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

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

interface IERC721CollectionMetadata {
    function contractURI() external returns (string memory);
}

library Bits {
    uint constant internal ONE = uint(1);

    function setBit(uint self, uint8 index) internal pure returns (uint) {
        return self | ONE << index;
    }

    function clearBit(uint self, uint8 index) internal pure returns (uint) {
        return self & ~(ONE << index);
    }

    function isBitSet(uint self, uint8 index) internal pure returns (bool) {
        return self >> index & 1 == 1;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

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

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

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
    function balanceOf(address owner) public view virtual returns (uint256) {
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
        address owner = ownerOf(tokenId);
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
        address owner = ownerOf(tokenId);
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
        address owner = ownerOf(tokenId);

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
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    ) internal returns (bool) {
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

interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

contract BillionDollarTokenPage is ERC721, IERC2981, Pausable, Ownable, IERC721Receiver, IERC721Enumerable, IERC721CollectionMetadata {
    using Address for address;
    using Bits for uint256;

    uint256 private mintedTokenCount;
    mapping(uint256 => string) private tokenContentURIs;

    uint16 public constant COLUMN_COUNT = 100;
    uint16 public constant ROW_COUNT = 100;
    uint16 public constant SUPPLY_LIMIT = COLUMN_COUNT * ROW_COUNT;

    uint16 public royaltyBasisPoints;
    uint16 public totalMintLimit;
    uint16 public singleMintLimit;
    uint16 public ownershipMintLimit;
    uint256 public mintPrice;
    bool public isSaleActive;
    bool public isCenterSaleActive;

    string public collectionURI;
    string public metadataBaseURI;
    string public defaultContentBaseURI;
    bool public isMetadataFinalized;

    bool public canAddTokenIdsToMigrate;
    uint256 private tokenIdsToMigrateCount;
    uint256[(SUPPLY_LIMIT / 256) + 1] private tokenIdsToMigrateBitmap;
    uint256[(SUPPLY_LIMIT / 256) + 1] private tokenIdsMigratedBitmap;

    event TokenContentURIChanged(uint256 indexed tokenId);
    event TokenMigrated(uint256 indexed tokenId);

    constructor(uint16 _totalMintLimit, uint16 _singleMintLimit, uint16 _ownershipMintLimit, uint256 _mintPrice, string memory _metadataBaseURI, string memory _defaultContentBaseURI, string memory _collectionURI, uint16 _royaltyBasisPoints) ERC721("BillionDollarTokenPage", "\u22A1") Ownable() Pausable() {
        isSaleActive = false;
        isCenterSaleActive = false;
        canAddTokenIdsToMigrate = true;
        metadataBaseURI = _metadataBaseURI;
        defaultContentBaseURI = _defaultContentBaseURI;
        collectionURI = _collectionURI;
        totalMintLimit = _totalMintLimit;
        singleMintLimit = _singleMintLimit;
        ownershipMintLimit = _ownershipMintLimit;
        mintPrice = _mintPrice;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721CollectionMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (address(this), salePrice * royaltyBasisPoints / 10000);
    }

    function contractURI() external view override returns (string memory) {
        return collectionURI;
    }

    modifier onlyValidToken(uint256 tokenId) {
        require(tokenId > 0 && tokenId <= SUPPLY_LIMIT, "BDTP: invalid tokenId");
        _;
    }

    modifier onlyValidTokenGroup(uint256 tokenId, uint8 width, uint8 height) {
        require(width > 0, "BDTP: width must be > 0");
        require(height > 0, "BDTP: height must be > 0");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "BDTP: caller is not token owner");
        _;
    }

    function isInMiddle(uint256 tokenId) internal pure returns (bool) {
        uint256 x = tokenId % COLUMN_COUNT;
        uint256 y = tokenId / ROW_COUNT;
        return x >= 38 && x <= 62 && y >= 40 && y <= 59;
    }

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setIsCenterSaleActive(bool newIsCenterSaleActive) external onlyOwner {
        isCenterSaleActive = newIsCenterSaleActive;
    }

    function setTotalMintLimit(uint16 newTotalMintLimit) external onlyOwner {
        totalMintLimit = newTotalMintLimit;
    }

    function setSingleMintLimit(uint16 newSingleMintLimit) external onlyOwner {
        singleMintLimit = newSingleMintLimit;
    }

    function setOwnershipMintLimit(uint16 newOwnershipMintLimit) external onlyOwner {
        ownershipMintLimit = newOwnershipMintLimit;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setCollectionURI(string calldata newCollectionURI) external onlyOwner {
        collectionURI = newCollectionURI;
    }

    function setMetadataBaseURI(string calldata newMetadataBaseURI) external onlyOwner {
        require(!isMetadataFinalized, 'BDTP: metadata is now final');
        metadataBaseURI = newMetadataBaseURI;
    }

    function setDefaultContentBaseURI(string calldata newDefaultContentBaseURI) external onlyOwner {
        defaultContentBaseURI = newDefaultContentBaseURI;
    }

    function setMetadataFinalized() external onlyOwner {
        require(!isMetadataFinalized, 'BDTP: metadata is now final');
        isMetadataFinalized = true;
    }

    function setRoyaltyBasisPoints(uint16 newRoyaltyBasisPoints) external onlyOwner {
        require(newRoyaltyBasisPoints >= 0, "BDTP: royaltyBasisPoints must be >= 0");
        require(newRoyaltyBasisPoints < 5000, "BDTP: royaltyBasisPoints must be < 5000 (50%)");
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view override onlyValidToken(tokenId) returns (string memory) {
        return string(abi.encodePacked(metadataBaseURI, Strings.toString(tokenId), ".json"));
    }

    function tokenContentURI(uint256 tokenId) external view onlyValidToken(tokenId) returns (string memory) {
        string memory _tokenContentURI = tokenContentURIs[tokenId];
        if (bytes(_tokenContentURI).length > 0) {
            return _tokenContentURI;
        }
        address owner = _owners[tokenId];
        if (owner != address(0)) {
            return tokenURI(tokenId);
        }
        return string(abi.encodePacked(defaultContentBaseURI, Strings.toString(tokenId), ".json"));
    }

    function setTokenContentURI(uint256 tokenId, string memory contentURI) external {
        _setTokenContentURI(tokenId, contentURI);
    }

    function setTokenGroupContentURIs(uint256 tokenId, uint8 width, uint8 height, string[] memory contentURIs) external {
        require(width * height == contentURIs.length, "BDTP: length of contentURIs incorrect");
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint16 index = (width * y) + x;
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                _setTokenContentURI(innerTokenId, contentURIs[index]);
            }
        }
    }

    function _setTokenContentURI(uint256 tokenId, string memory contentURI) internal onlyTokenOwner(tokenId) whenNotPaused {
        tokenContentURIs[tokenId] = contentURI;
        emit TokenContentURIChanged(tokenId);
    }

    function ownerMintTokenGroupTo(address receiver, uint256 tokenId, uint8 width, uint8 height) external onlyOwner {
        _safeMint(receiver, tokenId, width, height, true, "");
    }

    function mintToken(uint256 tokenId) external payable {
        require(msg.value >= mintPrice, "BDTP: insufficient payment");
        _safeMint(_msgSender(), tokenId, 1, 1);
    }

    function mintTokenTo(address receiver, uint256 tokenId) external payable {
        require(msg.value >= mintPrice, "BDTP: insufficient payment");
        _safeMint(receiver, tokenId, 1, 1);
    }

    function mintTokenGroup(uint256 tokenId, uint8 width, uint8 height) external payable {
        require(msg.value >= (mintPrice * width * height), "BDTP: insufficient payment");
        _safeMint(_msgSender(), tokenId, width, height);
    }

    function mintTokenGroupTo(address receiver, uint256 tokenId, uint8 width, uint8 height) external payable {
        require(msg.value >= (mintPrice * width * height), "BDTP: insufficient payment");
        _safeMint(receiver, tokenId, width, height);
    }

    function _safeMint(address receiver, uint256 tokenId, uint8 width, uint8 height) internal {
        _safeMint(receiver, tokenId, width, height, false, "");
    }

    function _safeMint(address receiver, uint256 tokenId, uint8 width, uint8 height, bool shouldIgnoreLimits, bytes memory _data) internal onlyValidTokenGroup(tokenId, width, height) {
        require(receiver != address(0), "BDTP: invalid address");
        require(tokenId > 0, "BDTP: invalid tokenId");
        require(tokenId + (ROW_COUNT * (height - 1)) + (width - 1) <= SUPPLY_LIMIT, "BDTP: invalid tokenId");
        uint256 quantity = (width * height);
        require(quantity > 0, "BDTP: insufficient quantity");
        if (!shouldIgnoreLimits) {
            require(isSaleActive, "BDTP: sale not active");
            require(balanceOf(receiver) + quantity <= ownershipMintLimit, "BDTP: over ownershipMintLimit");
            require(quantity <= singleMintLimit, "BDTP: over singleMintLimit");
            require(mintedCount() + quantity <= totalMintLimit, "BDTP: over totalMintLimit");
        }

        _beforeTokenTransfers(address(0), receiver, tokenId, width, height);
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                require(!_exists(innerTokenId), "BDTP: token already minted");
                require(isCenterSaleActive || !isInMiddle(innerTokenId), "BDTP: minting center not active");
                _owners[innerTokenId] = receiver;
                require(_checkOnERC721Received(address(0), receiver, innerTokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
                emit Transfer(address(0), receiver, innerTokenId);
            }
        }
        _balances[receiver] += quantity;
    }

    function mintedCount() public view returns (uint256) {
        return mintedTokenCount;
    }

    // Transfers

    function transferGroupFrom(address sender, address receiver, uint256 tokenId, uint8 width, uint8 height) public {
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                transferFrom(sender, receiver, innerTokenId);
            }
        }
    }

    function safeTransferGroupFrom(address sender, address receiver, uint256 tokenId, uint8 width, uint8 height) public {
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                safeTransferFrom(sender, receiver, innerTokenId);
            }
        }
    }

    function _beforeTokenTransfer(address sender, address receiver, uint256 tokenId) internal override {
        super._beforeTokenTransfer(sender, receiver, tokenId);
        _beforeTokenTransfers(sender, receiver, tokenId, 1, 1);
    }

    function _beforeTokenTransfers(address sender, address receiver, uint256, uint8 width, uint8 height) internal whenNotPaused {
        if (sender != receiver) {
            if (sender == address(0)) {
                mintedTokenCount += width * height;
            }
        }
    }

    function totalSupply() external pure override(IERC721Enumerable) returns (uint256) {
        return SUPPLY_LIMIT;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override(IERC721Enumerable) returns (uint256) {
        require(index < balanceOf(owner), "BDTP: owner index out of bounds");
        uint256 tokenIndex;
        for (uint256 tokenId = 1; tokenId <= SUPPLY_LIMIT; tokenId++) {
            if (_owners[tokenId] == owner) {
                if (tokenIndex == index) {
                    return tokenId;
                }
                tokenIndex++;
            }
        }
        revert('BDTP: unable to get token of owner by index');
    }

    function tokenByIndex(uint256 index) external pure override(IERC721Enumerable) returns (uint256) {
        require(index < SUPPLY_LIMIT, "BDTP: invalid index");
        return index + 1;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override whenNotPaused returns (bytes4) {
        tokenIdsToMigrateBitmap[tokenId / 256] = tokenIdsToMigrateBitmap[tokenId / 256].clearBit(uint8(tokenId % 256));
        tokenIdsMigratedBitmap[tokenId / 256] = tokenIdsMigratedBitmap[tokenId / 256].setBit(uint8(tokenId % 256));
        mintedTokenCount += 1;
        emit TokenMigrated(tokenId);
        return this.onERC721Received.selector;
    }

}