// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]opring.org>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract MetaData {
      function artworkDescription() public pure returns(string memory){
        return "Original marriage certificate of Ania Catherine and Dejha Ti. The institution of marriage historically has been an oppressive institution for women. The artists, who are married to each other and also have a collaborative art practice, consider their inhabitation of marriage to be both practical (1,138 rights are reserved for married couples in the U.S.), and also a durational subversive performance inhabiting a traditional institution in a queer and revolutionary way. Ti and Catherine convert something that has been a container for womens subservience to a foundation for a collaborative life of freedom, creativity, and a platform for their voices and ideas. The title, Let me check with the wife speaks to the mentioning of ones wife as a performative aspect of a certain genre of cis-heteromasculinity, which reveals itself as such when a woman does it. The collector of Let me check with the wife  receives the original physical copy of the artists marriage certificate, a digital image file version (modified to 9:16) as well as Marital Obligations (a dynamic NFT). The certificate has sensitive information censored for artist and family privacy";
      } 
      function medium() public pure returns(string memory){
        return "Scan of the original marriage certificate of Ania Catherine and Dejha Ti. The institution of marriage historically has been an oppressive institution for women. The artists, who are married to each other and also have a collaborative art practice, consider their inhabitation of marriage to be both practical (1,138 rights are reserved for married couples in the U.S.), and also a durational subversive performance inhabiting a traditional institution in a queer and revolutionary way. Ti and Catherine convert something that has been a container for womens subservience to a foundation for a collaborative life of freedom, creativity, and a platform for their voices and ideas. The title, Let me check with the wife speaks to the mentioning of ones wife as a performative aspect of a certain genre of cis-heteromasculinity, which reveals itself as such when a woman does it. The collector of Let me check with the wife  receives the original physical copy of the artists marriage certificate, a digital image file version (modified to 9:16) as well as Marital Obligations (a dynamic NFT). The certificate has sensitive information censored for artist and family privacy";
      } 
      function licenseAndCertificateOfMarriage() public pure returns(string memory){
        return "STATE OF CALIFORNIA CERTIFICATION OF VITAL RECORD COUNTY OF LOS ANGELES REGISTRAR-RECORDER/COUNTY CLERK 5 201719018002 CONFIDENTIAL LICENSE AND CERTIFICATE OF MARRIAGE MUST BE LEGIBLE - MAKE NO ERASURES, WHITEOUTS, OR OTHER ALTERATIONS USE DARK INK ONLY  LOCAL REGISTRATION NUMBER STATE FILE NUMBER [ ] Groom [x] Bride FIRST PERSON DATA 1A. FIRST NAME ANIA 1B. MIDDLE CATHERINE 1C. CURRENT LAST (CENSORED) 1D. LAST NAME AT BIRTH (IF DIFFERENT THAN 1C) 2. DATE OF BIRTH (MM/DD/CCYY) 02/19/1990 3. STATE/COUNTRY OF BIRTH CA 4. #PREV. MARRIAGE/SRDP 0 5A. LAST MARRIAGE/SRDP BY: [ ] DEATH [ ] DISSO [ ] ANNULMENT [ ] TERM SRDP [x]  N/A 5B. DATE ENDED (MM/DD/CCYY) --/--/---- 6. ADDRESS (CENSORED) ELECTRIC AVE 7. CITY VENICE 8. STATE/COUNTRY CA 9. ZIP CODE 90291 10A FULL BIRTH NAME OF FATHER/PARENT (CENSORED) 10B. STATE OF BIRTH (IF OUTSIDE U.S. ENTER COUNTRY) MEX 11A. FULL BIRTH NAME OF MOTHER/PARENT (CENSORED) 11B. STATE OF BIRTH (IF OUTSIDE U.S. ENTER COUNTRY) CA [  ] Groom [x] Bride SECOND PERSON DATA 12A. FIRST NAME DEJHA 12B. MIDDLE TI 12C. CURRENT LAST (CENSORED) 12D. LAST NAME AT BIRTH (IF DIFFERENT THAN 12C) 13. DATE OF BIRTH (MM/DD/CCYY) 08/19/1985 14. STATE/COUNTRY OF BIRTH FL 15. #PREV. MARRIAGE/SRDP 0 16A. LAST MARRIAGE/SRDP BY: [ ] DEATH [ ] DISSO [ ] ANNULMENT [ ] TERM SRDP [x] N/A 16B. DATE ENDED (MM/DD/CCYY) --/--/---- 17. ADDRESS (CENSORED) ELECTRIC AVE 18. CITY VENICE 19. STATE/COUNTRY CA 20. ZIP CODE 90291 21A FULL BIRTH NAME OF FATHER/PARENT (CENSORED) 21B. STATE OF BIRTH (IF OUTSIDE U.S. ENTER COUNTRY) FL 22A. FULL BIRTH NAME OF MOTHER/PARENT (CENSORED) 22B. STATE OF BIRTH (IF OUTSIDE U.S. ENTER COUNTRY) PA AFFIDAVIT WE, THE UNDERSIGNED, CURRENTLY LIVING TOGETHER AS SPOUSES, DECLARE UNDER PENALTY OF PERJURY UNDER THE LAWS OF THE STATE OF CALIFORNIA THAT WE ARE UNMARRIED AND THAT THE FOREGOING INFORMATION IS TRUE AND CORRECT TO BEST OF OUR KNOWLEDGE AND BELIEF. WE FURTHER DECLARE THAT NO LEGAL OBJECTION TO THE MARRIAGE, NOR TO THE ISSUANCE OF A LICENSE IS KNOWN TO US. WE ACKNOWLEDGE RECEIPT OF THE INFORMATION REQUIRED BY FAMILY CODE SECTION 358 AND HEREBY APPLY FOR A CONFIDENTIAL LICENSE AND CERTIFICATE OF MARRIAGE. 23. SIGNATURE OF PERSON LISTED IN FIELDS 1A-1D [SIGNATURE] 24. SIGNATURE OF PERSON LISTED IN FIELDS 12A-12D [SIGNATURE] LICENSE TO MARRY I, THE UNDERSIGNED, DO HEREBY CERTIFY THAT THE ABOVE-NAMED PARTIES TO BE MARRIED HAVE PERSONALLY APPEARED BEFORE ME  AND PROVED TO ME ON THE BASIS OF SATISFACTORY EVIDENCE TO BE THE PERSONS CLAIMED, OR THAT THE PERSON PERFORMING THE CEREMONY HAS PERSONALLY APPEARED BEFORE ME AND PRESENTED AN AFFIDAVIT SIGNED BY THE PARTIES TO BE MARRIED DECLARING THAT ONE OR BOTH OF THE PARTIES ARE PHYSICALLY UNABLE TO APPEAR AND EXPLAINING THE REASONS THEREFOR IN ACCORDANCE WITH FAMILY CODE SECTION 502. THE PARTIES HAVING FURTHER DECLARED THAT THEY MEET ALL THE REQUIREMENTS OF THE LAW, AND HAVING PAID THE FEES PRESCRIBED BY LAW, AUTHORIZATION AND LICENSE IS HEREBY GIVEN TO ANY PERSON DULY AUTHORIZED TO PERFORM A MARRIAGE CEREMONY WITHIN THE STATE OF CALIFORNIA, TO SOLEMNIZE THE MARRIAGE OF THE ABOVE-NAMED PERSONS PURSUANT TO FAMILY CODE SECTION 500. NOTE: THE MARRIAGE CEREMONY MUST TAKE PLACE IN THE STATE OF CALIFORNIA. 25A. ISSUE DATE (MM/DD/CCYY) 07/06/2017 25B. EXPIRES AFTER  (MM/DD/CCYY) 10/04/2017 25C. NAME OF COUNTY CLERK DEAN C. LOGAN 25D. SIGNATURE OF CLERK OR DEPUTY CLERK BY (CENSORED) 25E. MARRIAGE LICENSE NUMBER C2469551 25F. COUNTY OF ISSUE LOS ANGELES 25G. RETURN COMPLETED MARRIAGE LICENSE TO (INCLUDE ADDRESS): 12400 Imperial Highway, Norwalk, CA 90650 ITEMS 26A-26D COMPLETED ONLY IF LICENSE IS ISSUED BY NOTARY PUBLIC A NOTARY PUBLIC OR OTHER OFFICER COMPLETING THIS CERTIFICATE VERIFIES ONLY THE IDENTITY OF THE INDIVIDUAL WHO SIGNED THE DOCUMENT TO WHICH THIS CERTIFICATE IS ATTACHED, AND NOT THE TRUTHFULNESS, ACCURACY OR VALIDITY OF THAT DOCUMENT. 26A. STATE OF CALIFORNIA, COUNTY OF: ____________________________________ SUBSCRIBED AND SWORN TO (OR AFFIRMED) BEFORE ME ON THIS____DAY OF ________ 20______ BY _________________________ PROVED TO ME ON THE BASIS OF SATISFACTORY EVIDENCE TO BE THE PERSON(S) WHO APPEARED BEFORE ME. 26B. TYPED NAME OF NOTARY 26C. SIGNATURE OF NOTARY 26D. AFFIX NOTARY SEAL CERTIFICATION OF PERSON SOLEMNIZING MARRIAGE I, THE UNDERSIGNED, DECLARE UNDER PENALTY OF PERJURY UNDER THE LAWS OF THE STATE OF CALIFORNIA, THAT THE ABOVE-MENTIONED PARTIES WERE JOINED BY ME IN MARRIAGE IN ACCORDANCE WITH THE LAWS OF THE STATE OF CALIFORNIA. NOTE: THE MARRIAGE CEREMONY MUST TAKE PLACE IN THE STATE OF CALIFORNIA. 27A. DATE OF MARRIAGE (MM/DD/CCYY) 09/29/2017 (HANDWRITTEN) 27B. CITY OF MARRIAGE LOS ANGELES (HANDWRITTEN) 27C. COUNTY OF MARRIAGE LOS ANGELES (HANDWRITTEN) 28A. SIGNATURE OF PERSON SOLEMNIZING MARRIAGE [SIGNATURE] 28B. RELIGIOUS DENOMINATION (IF CLERGY) -UNITARIAN UNIVERSALIST (HANDWRITTEN) 28C. NAME OF PERSON SOLEMNIZING MARRIAGE (TYPE OR PRINT CLEARLY) (CENSORED) 28D. OFFICIAL TITLE WIZARD (HANDWRITTEN) 28E. ADDRESS, CITY, STATE/COUNTY, AND ZIP CODE (CENSORED) Blvd Venice, CA 90291 (HANDWRITTEN) NEW NAME(S) (IF ANY) (SEE REVERSE) NEW MIDDLE AND LAST NAME OF PERSON LISTED IN 1A-1D (IF ANY) FOR USE UPON SOLEMNIZATION OF THE MARRIAGE (SEE REVERSE FOR INFORMATION) 29A. FIRST - MUST BE SAME AS 1A 29B. MIDDLE 29C. LAST NEW MIDDLE AND LAST NAME OF PERSON LISTED IN 12A-12D (IF ANY) FOR USE UPON SOLEMNIZATION OF THE MARRIAGE (SEE REVERSE FOR INFORMATION) 30A. FIRST - MUST BE SAME AS 12A 30B. MIDDLE 30C. LAST COUNTY CLERK 31A. NAME OF COUNTY CLERK DEAN C. LOGAN 31B. SIGNATURE OF CLERK OR DEPUTY CLERK BY (CENSORED) 31C. DATE ACCEPTED FOR REGISTRATION NOV 03 2017 CALIFORNIA DEPARTMENT OF PUBLIC HEALTH - VITAL RECORDS VS-123 (01/01/2015) This is to certify that this document is a true copy of the official record filed with the Registrar-Recorder/County Clerk. [SIGNATURE] DEAN C. LOGAN Registrar-Recorder/County Clerk This copy is not valid unless prepared on an engraved border displaying the seal and signature of the Registrar-Recorder/County Clerk. NOV 09 2017 1000002054393 CALOSANG02 ANY ALTERATION OR ERASURE VOIDS THIS CERTIFICATE THE GREAT SEAL OF THE STATE OF CALIFORNIA EUREKA REGISTRAR-RECORDER/COUNTY CLERK COUNTY OF LOS ANGELES-CALIFORNIA";
      } 
      function reverseUtility() public pure returns(string memory){
        return 'As a hyperbolic flip on the expectation of utility with NFT artworks, and drawing on the concept of marital obligations, the collector will receive direction or might be expected to provide the artists with specific actions or gifts on their anniversary (July 19); this aspect of the artist-collector relationship is managed via a dynamic NFT entitled "Marital Obligations." In the case of divorce, there will be one final obligation and no further anniversary gifts expected. The QR code/Etherscan link added to the marriage certificate leads to the MaritalObligations smart contract which is the dynamic NFT and contains an on-chain transcription of the marriage certificate. This on-chain dynamic NFT is married to the primary contract, following it to whatever address owns it.';
      } 

      function archivalHygeine() public pure returns(string memory){
        return 'The "Let me check with the wife" (the "Artwork") primary smart contract generated on SuperRare is tied to the artists` original physical marriage certificate (a State of California issued vital record - License and Certificate of Marriage) and a digital copy (modified for 9:16) stored on IPFS managed by SuperRare-these digital and physical assets are not stored on the blockchain. To practice good archival hygiene and in the event that IPFS becomes unavailable and/or the physical marriage certificate is lost, the smart contract entitled MaritalObligations has been connected to the Artwork`s primary contract (see Etherscan link included in the primary contract`s attributes) and contains a text transcription of the original marriage certificate. By doing this, the artists` marriage certificate is fully stored on chain and is certified as the Artwork by the artists, Ania Catherine & Dejha Ti, and Operator LLC, a limited liability corporation based in Wyoming. Additionally, the physical marriage certificate includes a QR code stamp/Etherscan link to MaritalObligations. MaritalObligations contains the dynamic NFT (see Reverse Utility), which is married to the collector of the Artwork-this on-chain dynamic NFT is married to the primary contract, following it to whatever address owns it.';
      } 

      function termsOfUse() public pure returns(string memory){
        return 'Each token and deployed and governed by this smart contract (and any extensions thereof) (each, an "NFT") is associated with certain works of authorship or other content, whether or not copyrighted or copyrightable, and regardless of the format in which any of the foregoing is made available ("Related Content").  Related Content is separate from the associated NFT, and is not sold or otherwise transferred to the holder of such NFT, but is instead licensed to the holder as set forth in the Terms of Use available at https://www.operator.la/nft-tou (the "Terms").  Subject to compliance with the Terms, for as long as such owner holds an NFT, ownership of an NFT grants the holder the limited, personal, non-commercial, non-sublicensable, non-exclusive license to display and perform the Related Content associated with such NFT as more fully set forth in the Terms.  All other rights in and to the Related Content and any other intellectual property are reserved by Operator, LLC. Use of an NFT is subject to additional terms and conditions set forth in the Terms. Use of any token deployed and governed by this smart contract (and any extensions thereof) is additionally subject to the Terms of Use available at https://www.operator.la/nft-tou';
      } 
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Imports.sol";
import {Base64} from "base64-sol/base64.sol";

contract MaritalObligations is ERC721, Ownable{

  IERC721 linkage;
  bool linkageSet;
  uint linkageId;

  string[] public phrases;
  uint anniv = 1626678000;

  MetaData public md;

  constructor(MetaData _md, IERC721 _linkage, uint _id) ERC721("Operator", "Operator"){
    md = _md;
    linkage = _linkage;
    linkageId = _id;
    _mint(msg.sender, 1);
    phrases.push("We do.");
  }
  function ownerOf(uint256 _tokenId) public view override returns(address){
        if(linkageId != 0){
        return linkage.ownerOf(linkageId);
        } else {
          return linkage.ownerOf(_tokenId);
        }
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
      if(owner == ownerOf(1)){
        return 1;
      } else {
        return 0;
      }
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    require(from == address(0),"Token cannot be transfered");
  }

  function selector() public view returns(uint) {
    return (block.timestamp - anniv) / 52 weeks;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string[3] memory parts = ['<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" id="Layer_1" x="0" y="0" version="1.1" viewBox="0 0 1080 1920"> <style> .st0 { fill: #fff } div { color: white; font: 75px monospace; height: 100%; overflow: auto; } </style> <rect width="100%" height="100%" fill="black"></rect> <foreignObject x="100" y="500" width="766" height="700"> <div xmlns="http://www.w3.org/1999/xhtml">', phrases[selector()],'</div> </foreignObject> <svg x="10%" y="65%"> <g transform="scale(0.5)"> <path d="M254 694v-18l-13-29h10l8 20 7-20h10l-13 29v18h-9zm41 2c-6 0-10-2-13-7-3-4-5-10-5-18s2-15 5-19 7-6 13-6 11 2 14 6 4 10 4 19c0 8-1 14-4 18-3 5-8 7-14 7zm0-9c3 0 5-1 7-4l2-12-2-13c-2-3-4-4-7-4s-5 1-6 4l-2 13 2 12c1 3 3 4 6 4zm48-40h9v30c0 6-1 11-4 14s-7 5-12 5-9-2-12-5-4-8-4-14v-30h9v31l2 7c1 2 3 2 5 2s4 0 5-2l2-7v-31zm645 47-3-11h-13l-2 11h-10l13-47h12l12 47h-9zm-9-39-5 21h10l-5-21zm45 39-7-18h-6v18h-9v-47h14c5 0 9 1 12 3 3 3 4 6 4 11l-2 7-5 6 9 20h-10zm-9-25 6-2 2-6-2-5-6-2h-4v15h4zm31 25v-39h-10v-8h31v8h-11v39h-10zm26 0v-47h9v47h-9zm27-21c-4-1-6-3-8-5s-3-5-3-9 2-7 4-10c3-2 7-4 11-4 5 0 8 1 10 4 3 2 4 5 5 10l-9 1c0-3-1-4-2-5l-4-2-4 2-1 4 1 4 3 2 5 2c3 0 5 2 7 3l4 4 1 7c0 4-2 8-4 11-3 2-7 3-12 3-9 0-15-5-15-15h9l2 6c1 1 2 2 5 2l4-2 1-5-1-4-4-2-5-2zm33 21v-39h-11v-8h31v8h-11v39h-9zM297 568A273 273 0 0 1 22 293 273 273 0 0 1 297 18a273 273 0 0 1 275 275 273 273 0 0 1-275 275zm0-546A269 269 0 0 0 26 293a269 269 0 0 0 271 271 269 269 0 0 0 271-271A269 269 0 0 0 297 22zm430 575h660v4H727zm-708 0h554v4H19zm708-278h660v4H727z" class="st0" /> <path d="m1289 244-2 3-2 3-9 3h-2l-7-2h-5l-4 1-9 2-23 6h-2l2-1 13-5 4-2c2-1 2-3 1-4-1-2-3-3-5-3l-11-1-17 1h-2v-2l4-9c1-3 0-5-1-7l-1-2c-1-2-3-3-6-2s-6 3-8 6l-6 6a296 296 0 0 1-13 14h-2l1-2c4-3 4-4 1-7-1-2-3-3-5-1l-4 3-4-1c-1-3-3-3-5-2l-12 6-9 2-10 1-24 8c-2 1-3 1-3 3l3 5 2 1 8-1c6-1 12-4 17-6l11-4 11-3h2l1 1-5 1-1 2 3 9c1 1 1 2-1 4l-4 4-10 9-13 10-7 6-7 5-19 14-21 13-2 1-15 9-13 8-7 4-11 6-9 5-13 7-10 5-17 9-14 6-18 8-13 5-11 4-16 6a343 343 0 0 1-48 10c-5 1-10 0-15-1-6-2-10-7-12-14-1-5 0-10 1-16l3-10 5-13 9-16 9-11 6-8 5-6 3-3 1-1 6-7 11-11 13-11h2c3 1 5 1 8-1l8-3 6-3 11-5 6-3h1l11-5 2-1 7-3 6-3 5-2 8-3v2c2 2 4 3 7 1l4-2c2-1 2-2 2-3l2-1 2-2 2-1v1l1-2c0-2 2 0 2-1v-1c1-2 1-2 4-2l1-2v-1h1v-1l4 11c1 3 2 5 4 6 4 5 9 8 15 8h8l2-1 9-3 2-1 3-1 10-6 1-1 3-2 3-2 1-1c1 1 2 0 3-1 2-1 2-3 4-3h1l4-3 2-2 2-2c3 0 3-2 5-3l4-4h1l3-3 1-2 3-2 4-5 5-8 1-5c1-4 1-8-1-12l-4-5-3-4c-3-2-6-4-10-4h-1l-5-2h-1l-4 1-3 1-10 2-6 1c-3 0-5 2-8 3h-1l-7 3-3 1-3 2-4 1-8 4-3 2-7 3-2 1-6 4-4 2-2 1-8 4-3 2-3 2c-2 0-4 1-5 4h-3l-3 2-1 1-1 1c-2 0-3 2-5 3l-1 1-4 1v2l-2-1c0 2-2 3-4 3v1h-3l-9 3-16 5-9 4-16 6-13 6-14 6-11 6-8 3-17 7-10 5a764 764 0 0 1-28 9h-1l1-3 6-7 7-7 1-1 6-4 1-2 2-3c2 0 3-1 3-2 1-1 2-2 3-1-1-3 2-2 2-4l4-2 1-2c2-2 4-3 5-6h1l10-9 3-2h1l6-9 1-3c-2-3-5-6-9-5l-5 1-11 4-24 11-10 6-17 9-19 11-11 7-21 13-24 15-9 6-25 16h-1l1-2 2-2 4-4 6-4 11-10 4-4 5-4a98 98 0 0 0 16-14l2-1 2-2 2-1 12-9 11-10 11-8 12-9 6-5 11-7 21-14 3-2v-2l-1-1c-1-3-3-3-6-2l-4 2a544 544 0 0 0-25 18l-9 6-14 10-11 8-12 10-11 9-8 7-13 10-11 10-9 7-6 6-12 11-11 11-1 3c1 2 5 5 7 5l9-2a231 231 0 0 0 21-13l6-4 9-5 15-11 6-3 7-6 5-2 13-8 4-3 1-1 13-7 2-1 4-3 4-2 9-5 10-6 13-7 9-4 3-2 16-7 8-4h3l-1 2-4 4-9 8-16 14-9 8-8 7-9 10-5 6c-2 3-1 6 1 8 3 2 6 4 9 4l11-2 2-1 7-3 5-2 6-2 12-6h1l10-5 6-2 6-3 4-2h-2l4-2-1 2 7-4 2-1 3-1 10-4 25-11 6-2h4c-3 0-3 2-4 3h-1l-4 2-3 2v1c-1-1-2 0-2 1l-7 4-11 6-12 8c-2 1-2 1-1 3l-1 2c-1 2-2 5-5 5v3c-3-1-3-1-3 2-2-1-2-1-3 1l-3 4-3 1-3 4-1 2-2 1-5 5-1 1-2 3c-3 1-3 2-2 4h-2l-7 8-1 1-2 2-1 2-1 1-3 3-5 8-1 1-1 3-5 8-2 4-1 2-2 7-2 3-1 4v3l-1 2-1 1-1 5-1 4v-2l1-11v-1l1-3 1-5-1 1-2 9-1 1-1 2v17l5 9 9 7 13 4c7 1 14 1 21-1l9-1 12-3 9-3 10-3 11-4 9-4 10-3 2-1 1-1 6-2 8-3 13-7 4-2 6-2 7-4h1l6-3 9-5 12-6 14-7 6-4 10-5 5-4 11-6 3-3 5-2 3-2 4-2 3-3h2l5-4h1l1-1 6-4 14-10 15-10 18-15 8-6 5-5 4-2 1 4v2l1 2v2l2 7 2 10 1 3 1 6a65 65 0 0 1 1 8l3 4 4 1 2-1 4-9 5-13 2-5 5-12 6-10h6l13-4 6-1 9-2 7-2 8-3 13-3 5-1 7 2c3 1 7 1 10-1l4-2 1 2c0 2 2 2 3 3s2 0 2-1v-4l1-8v-4h-3zm-157 7-8 3h-4c-2 2-4 2-5 2a2033 2033 0 0 0-4 0l10-3 11-3h1l-1 1zm-258 35 1-1 5-2 1 1-7 2zm73-19c2 0 3-1 3-3 0-1 1-2 3-1 2 0 3-1 5-3l-4 1h-3c1-2 2-1 3-1l2-2 2-2 7-5 6-3-1-5 10-6 3-2v-1h2l8-5 13-7 10-5 9-4 4-3 10-5 14-6c5-2 11-5 17-6l8-2 9-1 12 1 9 4 3 3 1 6v3l-2 6-4 6c-3 5-7 8-11 12l-7 5a367 367 0 0 1-42 26l-12 4-9-1c-4-2-6-5-7-9s-2-9-1-14l-1-4-2-2-2-2-2 2v3l-1 2-13 11c-1 1-1 1-3-1l-3-1-15 6-26 11-3 1 1-1zM824 403c-2-1-1-2-1-4l1 3v1zm339-153h1v1h-1v-1zm32 8-5 12-7 14-5 12-7 17-1 2v-2l-2-9-2-3v-1l-1-3-1-4-2-7v-2l-1-2v-5l-1-2 1-2-1-4h2l3-1 6-5 8-6 3-2 11-2h4l-2 5zm3-11-10 1-3-1h2v-2l3-4 1-1 3-1c2-2 4-4 7-4l1-1 2-2v1l-3 12-3 2zm20 9-12 4-3 1v-1l2-6c1-2 2-2 3-2l13-1 8-1h2l-1 1-12 5zm170 17v-6c-1-4-1-7-3-10l-3-4-10-4h-31l-19 5-1 1h4l12-1h26l12 2c4 1 5 3 6 6l1 8 2 6 2 2h2v-5zm-92 71-1 1 1 1 1-1-1-1zm-337-85h-1 1zm349 286-22-10-21-6-7-2 19-26 5-7 3-4v-1 1-1l2-3 1-1 7-10c7-8 12-17 17-27l-1-1 2-3c0-3-2-4-5-4l-10 2h-1c-14 5-26 13-36 23l-13 14-2 1v1a234 234 0 0 0-20 30l-1 1-1 3-4 4c-2 2-4 5-6 5l-19 1-5 1v2l14 11-10 13c-10-12-18-1-27 2 1-4 2-8-3-9h-11l-10 6-25 20-10 8c2-4 2-7 4-9l4-7 10-16 9-12 2-4c2 0 2-2 3-3l10-14 25-36c3-5 3-8 0-12l-4 3-32 45a1691 1691 0 0 0-41 65c0 1 1 5 3 6 3 1 7 4 11 0l7-6 27-23 8-6 3 1-19 23c3 5 8 7 12 4l19-16c4-4 9-6 14-9l1 1-1 3-26 33c-1 1-2 3-1 4 1 4 10 4 12 1l12-14 16-20-1-4 3 1 3-4h-2l9-12c0 6 4 7 9 7l-6-15c9-4 19-1 30-3l-21 28-33 42c-5 8-12 15-18 22-1 2-1 3 2 4 5 2 8 1 12-5l22-30 18-23-1-1c7-7 13-15 18-24h1l6-8 1-1 1-2 8 1c11 3 23 5 35 10 7 2 14 7 20 12 4 2 4 7 2 11-4 9-11 16-18 22l-38 26-12 7c-4 1-5 3-7 6 3 5 8 6 12 3l18-12 20-12 2-1 2-2 2-2v1l6-6 6-6h1c0-1 0 0 0 0l10-10c3-4 6-8 6-14 0-11-7-18-16-22zm-182 0zm7-10h2-2zm13 21v-2 2zm62-22v-1c1 0 1 0 0 0h1v1h-1zm65-34v-1 1zm-45 24h-5l17-28 1-2a208 208 0 0 1 10-14c11-9 23-18 36-24v-1l5-1-1 1 1-1 6-1-2 4-48 66c-1 2-3 2-6 2l-14-1zm-6 44zm18-24zm7-8zm61 55zm-207-39-6-2-23 8-37 19-13 6-2-2 10-12 15-12c1-1 2-4 1-5l-4-3-6 2-11 10c-6 6-14 10-22 14l-1-1 16-15-3-6-6 2-18 19c-1 1 0 4 1 5 2 4 7 5 11 4l7-1 6 6c6 4 12 1 17-2l5-2 21-7 3-2 6-3 12-5 6-3-23 28-50 67c-15 21-28 43-42 65-5 8-8 17-12 25-1 2 0 4 1 5 4 3 11-1 12-7l1-7 8-15 28-43v-1l1-1h-1l1-2 3-4 6-10 10-12v-2l4-4a71 71 0 0 1 1-2l15-20 25-32 29-34c2-2 1-5-2-6zm-41 20h1l3-1 2-1-5 2h-1zm15-6 1-1-1 1zm-28 11h2-2zm-79-3 19-32c2-1 23-39 23-42l4-8 10-19 9-16 13-23 8-12 12-21 19-29c3-4 5-8 0-13l-3 2-8 13-35 60-25 46-21 40-22 37-21 29 3-6 2-4a305 305 0 0 1 7-15l3-7h1l9-21-1-1 1-2 1-6h1v-3l-1-7-1-2-1-3c-2-3-5-7-9-7l-15 2c-11 3-20 9-29 15a150 150 0 0 0-38 28l-17 17c-4 5-8 11-10 17l-2 1c-2 3-5 8-1 12 3 3 7 6 11 7 10 3 21 0 30-3l14-3 14-5-19 3-30 4c-8 0-11-3-12-11l-1 1 3-7 5-8 4-6 10-11 8-8 15-12 21-12 18-10 1-1 17-4c4 0 8 3 7 7l-4 20-34 72c-3 8-3 8 6 9l7-9 7-11 5-8h1l11-14zm-74 23v1h-1l1-1zm252-104 2-7 7-6h-6l6-4h-4c-3 1-7 2-8 4-2 4-2 9-2 14l3-2 2 1zm203 26-5-5c-3 1-5 3-6 6-2 2 3 6 5 6 4 0 6-2 6-7z" class="st0" /> <path d="m1289 456 2-1a202 202 0 0 0-2 1zm2-1zm-115 159h-1 1zm32-81z" class="st0" /> </g> </svg> </svg>'];
    string memory svgData = string(abi.encodePacked(parts[0], parts[1],parts[2]));
    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "Marital Obligations"',
                    ', "description": "Ania Catherine and Dejha Ti`s [Let Me Check with the Wife] (2022), the duo`s marriage certificate in physical and digital formats is completed with this dynamic NFT entitled [Marital Obligations]. As a hyperbolic flip on the expectation of utility with NFT artworks, and drawing on the concept of marital obligations, the collector will receive direction or might be expected to provide the artists with specific actions or gifts on their anniversary (July 19); this aspect of the artist-collector relationship is managed via a dynamic NFT entitled [Marital Obligations] which is non-transferable. In the case of divorce, there will be one final obligation and no further anniversary gifts expected. The QR code/Etherscan link added to the marriage certificate leads to the MaritalObligations smart contract which is connected directly to the dynamic NFT and contains an on-chain transcription of the marriage certificate.",',
                    '"image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(svgData)),
                    '"}'
                )
            )
        )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
}

  function artWorkDescription() public view returns(string memory) {
      return md.artworkDescription();
  }

  function medium() public view returns(string memory) {
      return md.medium(); 
  }

  function licenseAndCertificateOfMarriage() public view returns(string memory) {
      return md.licenseAndCertificateOfMarriage(); 
  }

  function reverseUtility() public view returns(string memory) {
      return md.reverseUtility();
  }

  function archivalHygeine() public view returns(string memory) {
      return md.archivalHygeine(); 
  }

  function termsOfUse() public view returns(string memory) {
    return md.termsOfUse();
  }

  function setLinkage(IERC721 _linkage,uint _id) public onlyOwner { 
    require(linkageSet == false,"Linkage already set and cannot be updated");
    linkage = _linkage;
    linkageId = _id;
  }

  function finalizeLinkage() public onlyOwner {
    require(linkageSet == false,"Linkage already set and cannot be updated");
    linkageSet = true;
  }

  function writeMessage(string memory _string) public onlyOwner{
    require(msg.sender == owner(), 'Not operator and cannot write to array');
    phrases.push(_string);
  }

  function alertMessage(string memory _string) public onlyOwner{
    require(msg.sender == owner(), 'Not operator and cannot write to array');
    phrases[selector()] = _string;
  }

  function editMessage(string memory _string, uint index) public onlyOwner {
    phrases[index] = _string;
  }

}