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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DragonEgg.sol";
import "./DragonReproduction.sol";
import "./DragonGenetics.sol";

struct dragonAttributes {
    uint8 constitution;
    uint8 strength;
    uint8 dexterity;
    uint8 spirit;
    uint8 intelligence;
}

struct dragon {
    uint256 dragonId;
    string name;
    dragonAttributes attributes;
    uint256 motherId;
    uint256 fatherId;
    bool gender; // true is female false is male
    uint8 color; // from 0 to 255
    uint8 level; // from 0 to 255
    DragonGenes dragonGenes;
    uint256 dragonEggId;
    uint256 readyTimeToLayAnEgg;
    uint256 birthday;
}

uint256 constant TIAMAT_DRAGON_ID = 0;
uint256 constant BAHAMUT_DRAGON_ID = 1;

contract Dragon is ERC721, Ownable, DragonReproduction {
    using Counters for Counters.Counter;
    Counters.Counter private dragonCounter; // used to auto generate dragonIds

    mapping(uint256 => dragon) private dragons;

    constructor() ERC721("Dragon", "DRAGON") {
        _mint(address(this), TIAMAT_DRAGON_ID); // Tiamat
        _mint(address(this), BAHAMUT_DRAGON_ID); // Bahamut
        dragonCounter.increment();
        dragonCounter.increment();
    }

    function setDragonEggContractAddress(address _address) external onlyOwner {
        _setDragonEggContractAddress(_address);
    }

    function _createNewDragon(newDragonData memory _newDragonData)
        private
        returns (uint256 dragonId)
    {
        uint256 _dragonId = dragonCounter.current();

        dragonAttributes memory attributes = _calculateDragonAttributes(
            _newDragonData.dragonGenes.dominantGenes
        );

        dragon memory _newDragon = dragon(
            _dragonId,
            "",
            attributes,
            _newDragonData.motherId,
            _newDragonData.fatherId,
            _newDragonData.gender,
            _newDragonData.color,
            1, // level 1 by default
            _newDragonData.dragonGenes,
            _newDragonData.dragonEggId,
            _newDragonData.readyTimeToLayAnEgg, // readyTimeToLayAnEgg
            block.timestamp // birthday
        );

        dragons[_dragonId] = _newDragon;

        _mint(_newDragonData.owner, _dragonId);

        dragonCounter.increment();

        return _dragonId;
    }

    function birthNewDragon(dragonEgg memory _dragonEgg, address _dragonOwner)
        external
        returns (uint256 _babyDragonId)
    {
        // only DragonEgg contract can call this function
        require(
            msg.sender == address(dragonEggInterface),
            "only DragonEgg contract can call this function"
        );

        dragon memory _motherDragon = getDragon(_dragonEgg.motherId);
        dragon memory _fatherDragon = getDragon(_dragonEgg.fatherId);

        newDragonData memory babyDragonData;

        bool isRandomDragon = _dragonEgg.motherId == TIAMAT_DRAGON_ID &&
            _dragonEgg.fatherId == BAHAMUT_DRAGON_ID;

        if (isRandomDragon) {
            babyDragonData = _createNewRandomDragon(
                _dragonEgg.dragonEggId,
                _dragonOwner
            );
        } else {
            babyDragonData = _birthNewDragon(
                _motherDragon,
                _fatherDragon,
                _dragonEgg.dragonEggId,
                _dragonOwner
            );
        }

        _babyDragonId = _createNewDragon(babyDragonData);

        return _babyDragonId;
    }

    function reproduceDragons(uint256 _motherId, uint256 _fatherId)
        external
        returns (uint256[2] memory _dragonEggIds)
    {
        // TODO: change this, no needed to be owner of both dragons
        require(ownerOf(_motherId) == msg.sender);
        require(ownerOf(_fatherId) == msg.sender);

        return
            _reproduceDragons(
                dragons[_motherId],
                dragons[_fatherId],
                ownerOf(_motherId),
                ownerOf(_fatherId)
            );
    }

    function createRandomDragonEgg() external returns (uint256 dragonEggId) {
        // TODO: IMPLEMENT A PAYABLE METHOD BASED ON THE NUMBER OF DRAGONS
        // TODO: CREATE AN AUCTION EGGs FEATURE ?

        // 0 TO 100 DRAGONS : 0.01
        // 100 TO 1.000 DRAGONS : 0.1
        // 1.000 TO 10.000 DRAGONS : 1
        // 10.000 TO 100.000 DRAGONS : 10
        // >100.000 DRAGONS : 100

        return _createRandomDragonEgg(msg.sender);
    }

    function _createNewRandomDragon(uint256 _dragonEggId, address _owner)
        private
        returns (newDragonData memory)
    {
        return
            newDragonData(
                TIAMAT_DRAGON_ID,
                BAHAMUT_DRAGON_ID,
                _randomBetween(1, 2) == 1, // random gender
                uint8(_randomBetween(0, 255)), // random color
                _generateRandomDragonGenes(), // random genes
                _dragonEggId,
                block.timestamp,
                _owner
            );
    }

    // TODO: DELETE THIS DEV PURPOSSES ONLY
    function deleteDragon(uint256 _dragonId) external {
        _burn(_dragonId);
    }

    function getDragon(uint256 _dragonId) public view returns (dragon memory) {
        return dragons[_dragonId];
    }

    function getOwnerOfDragon(uint256 _dragonId)
        public
        view
        returns (address owner)
    {
        return ownerOf(_dragonId);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Dragon.sol";

uint256 constant HATCHING_TIME = 5 minutes;

interface DragonInterface {
    function birthNewDragon(dragonEgg memory _dragonEgg, address _dragonOwner)
        external
        returns (uint256 dragonId);
}

struct dragonEgg {
    uint256 dragonEggId;
    uint256 motherId;
    uint256 fatherId;
    uint256 hachingDate;
}

contract DragonEgg is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private dragonEggCounter; // used to auto generate dragonEggIds

    DragonInterface dragonInterface;

    mapping(uint256 => dragonEgg) private dragonEggs;

    constructor() ERC721("Dragon's Egg", "EGG") {}

    function setDragonContractAddress(address _address) external onlyOwner {
        dragonInterface = DragonInterface(_address);
    }

    function createDragonEgg(
        uint256 _motherId,
        uint256 _fatherId,
        address _owner
    ) external returns (uint256 dragonEggId) {
        // only Dragon contract can call this function
        require(
            msg.sender == address(dragonInterface),
            "only Dragon contract can call this function"
        );

        uint256 _dragonEggId = dragonEggCounter.current();

        uint256 _hachingDate = block.timestamp + HATCHING_TIME;

        dragonEgg memory _newDragonEgg = dragonEgg(
            _dragonEggId,
            _motherId,
            _fatherId,
            _hachingDate
        );

        dragonEggs[_dragonEggId] = _newDragonEgg;

        _mint(_owner, _dragonEggId);

        dragonEggCounter.increment();

        return _dragonEggId;
    }

    function hatchDragonEgg(uint256 _dragonEggId)
        external
        returns (uint256 _dragonId)
    {
        require(
            ownerOf(_dragonEggId) == msg.sender,
            "only the owner of the dragon's Egg can hatch the egg"
        );

        dragonEgg memory _dragonEgg = getDragonEgg(_dragonEggId);

        require(
            _dragonEgg.hachingDate <= block.timestamp,
            "Dragon's Egg is not ready to hatch"
        );

        _dragonId = dragonInterface.birthNewDragon(
            _dragonEgg,
            ownerOf(_dragonEggId)
        );

        // after the hatch the dragon egg is deleted
        _burn(_dragonEggId);

        return _dragonId;
    }

    function getDragonEgg(uint256 _dragonEggId)
        public
        view
        returns (dragonEgg memory)
    {
        return dragonEggs[_dragonEggId];
    }

    function getDragonEggOwner(uint256 _dragonEggId)
        public
        view
        returns (address)
    {
        return ownerOf(_dragonEggId);
    }

    // TODO: DELETE THIS DEV PURPOSSES ONLY
    function deleteDragonEgg(uint256 _dragonEggId) external {
        _burn(_dragonEggId);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

import "./DragonUtils.sol";
import "./Dragon.sol";

uint8 constant NUM_OF_ATTRIBUTES = 5; // constitution, strength, dexterity, spirit & intelligence
uint8 constant ATTRIBUTE_ADJUST = 135; // to make sure that attibute value is between [45, 255]
uint256 constant GEN_SUMMATORY = 10; // sumamtory of a gen is always 10

uint256 constant CON_GEN_INDEX = 0; // constitution position in the gen array
uint256 constant STR_GEN_INDEX = 1; // strength position in the gen array
uint256 constant DEX_GEN_INDEX = 2; // dexterity position in the gen array
uint256 constant SPI_GEN_INDEX = 3; // spirit position in the gen array
uint256 constant INT_GEN_INDEX = 4; // intelligence position in the gen array

uint8 constant DOMINANT_GENES_PROBABILITY = 80; // 80%
uint8 constant RECESIVE_1_GENES_PROBABILITY = 10; // 10%
uint8 constant RECESIVE_2_GENES_PROBABILITY = 10; // 10%

struct Gen {
    uint8[NUM_OF_ATTRIBUTES] firstGen;
    uint8[NUM_OF_ATTRIBUTES] secondGen;
    uint8[NUM_OF_ATTRIBUTES] thirdGen;
}

struct Genes {
    Gen constitution;
    Gen strength;
    Gen dexterity;
    Gen spirit;
    Gen intelligence;
}

struct DragonGenes {
    Genes dominantGenes;
    Genes recesive1Genes;
    Genes recesive2Genes;
}

contract DragonGenetics is DragonUtils {
    function _generateRandomGen(uint256 _atributeIndex)
        private
        returns (uint8[NUM_OF_ATTRIBUTES] memory _gen)
    {
        uint256 _randomValue = _randomBetween(10, 40); // a random value between [10, 40]
        uint256 _attributeValue = _randomValue -
            ((_randomValue - GEN_SUMMATORY) % 3); // trick to get a value divisible by 3
        uint256 _attributtePenalty = (_attributeValue - GEN_SUMMATORY) / 3; // penalty for other 3 attributes
        uint256 _attributeWithoutPenaltyIndex = (_randomBetween(1, 4) +
            _atributeIndex) % NUM_OF_ATTRIBUTES;

        _gen[CON_GEN_INDEX] = uint8(_attributtePenalty);
        _gen[STR_GEN_INDEX] = uint8(_attributtePenalty);
        _gen[DEX_GEN_INDEX] = uint8(_attributtePenalty);
        _gen[SPI_GEN_INDEX] = uint8(_attributtePenalty);
        _gen[INT_GEN_INDEX] = uint8(_attributtePenalty);
        _gen[_atributeIndex] = uint8(_attributeValue);
        _gen[_attributeWithoutPenaltyIndex] = 0;

        return _gen;
    }

    function _generateRandomGenes() private returns (Genes memory) {
        return
            Genes(
                // Constitution random Genes
                Gen(
                    _generateRandomGen(CON_GEN_INDEX), // first gen
                    _generateRandomGen(CON_GEN_INDEX), // second gen
                    _generateRandomGen(CON_GEN_INDEX) // third gen
                ),
                // Strength random Genes
                Gen(
                    _generateRandomGen(STR_GEN_INDEX), // first gen
                    _generateRandomGen(STR_GEN_INDEX), // second gen
                    _generateRandomGen(STR_GEN_INDEX) // third gen
                ),
                // Dexterity random Genes
                Gen(
                    _generateRandomGen(DEX_GEN_INDEX), // first gen
                    _generateRandomGen(DEX_GEN_INDEX), // second gen
                    _generateRandomGen(DEX_GEN_INDEX) // third gen
                ),
                // Spirit random Genes
                Gen(
                    _generateRandomGen(SPI_GEN_INDEX), // first gen
                    _generateRandomGen(SPI_GEN_INDEX), // second gen
                    _generateRandomGen(SPI_GEN_INDEX) // third gen
                ),
                // Intelligence random Genes
                Gen(
                    _generateRandomGen(INT_GEN_INDEX), // first gen
                    _generateRandomGen(INT_GEN_INDEX), // second gen
                    _generateRandomGen(INT_GEN_INDEX) // third gen
                )
            );
    }

    function _generateRandomDragonGenes()
        internal
        returns (DragonGenes memory)
    {
        return
            DragonGenes(
                _generateRandomGenes(), // dominantGenes
                _generateRandomGenes(), // recesive1Genes
                _generateRandomGenes() // recesive2Genes
            );
    }

    function _calculateDragonAttributes(Genes memory _genes)
        internal
        pure
        returns (dragonAttributes memory)
    {
        uint8 constitution = _calculateContitution(_genes);
        uint8 strength = _calculateStrength(_genes);
        uint8 dexterity = _calculateDexterity(_genes);
        uint8 spirit = _calculateSpirit(_genes);
        uint8 intelligence = _calculateIntelligence(_genes);

        return
            dragonAttributes(
                constitution,
                strength,
                dexterity,
                spirit,
                intelligence
            );
    }

    function _calculateContitution(Genes memory _genes)
        private
        pure
        returns (uint8)
    {
        return
            ATTRIBUTE_ADJUST +
            _genes.constitution.firstGen[CON_GEN_INDEX] +
            _genes.constitution.secondGen[CON_GEN_INDEX] +
            _genes.constitution.thirdGen[CON_GEN_INDEX] -
            _genes.strength.firstGen[CON_GEN_INDEX] -
            _genes.strength.secondGen[CON_GEN_INDEX] -
            _genes.strength.thirdGen[CON_GEN_INDEX] -
            _genes.dexterity.firstGen[CON_GEN_INDEX] -
            _genes.dexterity.secondGen[CON_GEN_INDEX] -
            _genes.dexterity.thirdGen[CON_GEN_INDEX] -
            _genes.spirit.firstGen[CON_GEN_INDEX] -
            _genes.spirit.secondGen[CON_GEN_INDEX] -
            _genes.spirit.thirdGen[CON_GEN_INDEX] -
            _genes.intelligence.firstGen[CON_GEN_INDEX] -
            _genes.intelligence.secondGen[CON_GEN_INDEX] -
            _genes.intelligence.thirdGen[CON_GEN_INDEX];
    }

    function _calculateStrength(Genes memory _genes)
        private
        pure
        returns (uint8)
    {
        return
            ATTRIBUTE_ADJUST +
            _genes.strength.firstGen[STR_GEN_INDEX] +
            _genes.strength.secondGen[STR_GEN_INDEX] +
            _genes.strength.thirdGen[STR_GEN_INDEX] -
            _genes.constitution.firstGen[STR_GEN_INDEX] -
            _genes.constitution.secondGen[STR_GEN_INDEX] -
            _genes.constitution.thirdGen[STR_GEN_INDEX] -
            _genes.dexterity.firstGen[STR_GEN_INDEX] -
            _genes.dexterity.secondGen[STR_GEN_INDEX] -
            _genes.dexterity.thirdGen[STR_GEN_INDEX] -
            _genes.spirit.firstGen[STR_GEN_INDEX] -
            _genes.spirit.secondGen[STR_GEN_INDEX] -
            _genes.spirit.thirdGen[STR_GEN_INDEX] -
            _genes.intelligence.firstGen[STR_GEN_INDEX] -
            _genes.intelligence.secondGen[STR_GEN_INDEX] -
            _genes.intelligence.thirdGen[STR_GEN_INDEX];
    }

    function _calculateDexterity(Genes memory _genes)
        private
        pure
        returns (uint8)
    {
        return
            ATTRIBUTE_ADJUST +
            _genes.dexterity.firstGen[DEX_GEN_INDEX] +
            _genes.dexterity.secondGen[DEX_GEN_INDEX] +
            _genes.dexterity.thirdGen[DEX_GEN_INDEX] -
            _genes.strength.firstGen[DEX_GEN_INDEX] -
            _genes.strength.secondGen[DEX_GEN_INDEX] -
            _genes.strength.thirdGen[DEX_GEN_INDEX] -
            _genes.constitution.firstGen[DEX_GEN_INDEX] -
            _genes.constitution.secondGen[DEX_GEN_INDEX] -
            _genes.constitution.thirdGen[DEX_GEN_INDEX] -
            _genes.spirit.firstGen[DEX_GEN_INDEX] -
            _genes.spirit.secondGen[DEX_GEN_INDEX] -
            _genes.spirit.thirdGen[DEX_GEN_INDEX] -
            _genes.intelligence.firstGen[DEX_GEN_INDEX] -
            _genes.intelligence.secondGen[DEX_GEN_INDEX] -
            _genes.intelligence.thirdGen[DEX_GEN_INDEX];
    }

    function _calculateSpirit(Genes memory _genes)
        private
        pure
        returns (uint8)
    {
        return
            ATTRIBUTE_ADJUST +
            _genes.spirit.firstGen[SPI_GEN_INDEX] +
            _genes.spirit.secondGen[SPI_GEN_INDEX] +
            _genes.spirit.thirdGen[SPI_GEN_INDEX] -
            _genes.dexterity.firstGen[SPI_GEN_INDEX] -
            _genes.dexterity.secondGen[SPI_GEN_INDEX] -
            _genes.dexterity.thirdGen[SPI_GEN_INDEX] -
            _genes.strength.firstGen[SPI_GEN_INDEX] -
            _genes.strength.secondGen[SPI_GEN_INDEX] -
            _genes.strength.thirdGen[SPI_GEN_INDEX] -
            _genes.constitution.firstGen[SPI_GEN_INDEX] -
            _genes.constitution.secondGen[SPI_GEN_INDEX] -
            _genes.constitution.thirdGen[SPI_GEN_INDEX] -
            _genes.intelligence.firstGen[SPI_GEN_INDEX] -
            _genes.intelligence.secondGen[SPI_GEN_INDEX] -
            _genes.intelligence.thirdGen[SPI_GEN_INDEX];
    }

    function _calculateIntelligence(Genes memory _genes)
        private
        pure
        returns (uint8)
    {
        return
            ATTRIBUTE_ADJUST +
            _genes.intelligence.firstGen[INT_GEN_INDEX] +
            _genes.intelligence.secondGen[INT_GEN_INDEX] +
            _genes.intelligence.thirdGen[INT_GEN_INDEX] -
            _genes.spirit.firstGen[INT_GEN_INDEX] -
            _genes.spirit.secondGen[INT_GEN_INDEX] -
            _genes.spirit.thirdGen[INT_GEN_INDEX] -
            _genes.dexterity.firstGen[INT_GEN_INDEX] -
            _genes.dexterity.secondGen[INT_GEN_INDEX] -
            _genes.dexterity.thirdGen[INT_GEN_INDEX] -
            _genes.strength.firstGen[INT_GEN_INDEX] -
            _genes.strength.secondGen[INT_GEN_INDEX] -
            _genes.strength.thirdGen[INT_GEN_INDEX] -
            _genes.constitution.firstGen[INT_GEN_INDEX] -
            _genes.constitution.secondGen[INT_GEN_INDEX] -
            _genes.constitution.thirdGen[INT_GEN_INDEX];
    }

    function calculateNewDragonGender() internal returns (bool) {
        // 50% female and 50% male
        uint256 _randomGender = _randomBetween(1, 2);
        bool _newDragonGender = _randomGender == 1;

        return _newDragonGender;
    }

    function calculateNewDragonColor(
        uint8 _motherDragonColor,
        uint8 _fatherDragonColor
    ) internal returns (uint8) {
        // 50% color from mother & 50% color from father
        bool isMotherColor = _randomBetween(1, 2) == 1;

        if (isMotherColor) {
            return _motherDragonColor;
        } else {
            return _fatherDragonColor;
        }
    }

    function calculateNewDragonGenes(
        DragonGenes memory _motherDragonGenes,
        DragonGenes memory _fatherDragonGenes
    ) internal returns (DragonGenes memory) {
        Genes memory _newDragonDominantGenes = Genes(
            // Constitution Genes
            Gen(
                // first gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.constitution.firstGen,
                    _motherDragonGenes.recesive1Genes.constitution.firstGen,
                    _motherDragonGenes.recesive2Genes.constitution.firstGen,
                    _fatherDragonGenes.dominantGenes.constitution.firstGen,
                    _fatherDragonGenes.recesive1Genes.constitution.firstGen,
                    _fatherDragonGenes.recesive2Genes.constitution.firstGen
                ),
                // second gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.constitution.secondGen,
                    _motherDragonGenes.recesive1Genes.constitution.secondGen,
                    _motherDragonGenes.recesive2Genes.constitution.secondGen,
                    _fatherDragonGenes.dominantGenes.constitution.secondGen,
                    _fatherDragonGenes.recesive1Genes.constitution.secondGen,
                    _fatherDragonGenes.recesive2Genes.constitution.secondGen
                ),
                // third gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.constitution.thirdGen,
                    _motherDragonGenes.recesive1Genes.constitution.thirdGen,
                    _motherDragonGenes.recesive2Genes.constitution.thirdGen,
                    _fatherDragonGenes.dominantGenes.constitution.thirdGen,
                    _fatherDragonGenes.recesive1Genes.constitution.thirdGen,
                    _fatherDragonGenes.recesive2Genes.constitution.thirdGen
                )
            ),
            // Strength Genes
            Gen(
                // first gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.strength.firstGen,
                    _motherDragonGenes.recesive1Genes.strength.firstGen,
                    _motherDragonGenes.recesive2Genes.strength.firstGen,
                    _fatherDragonGenes.dominantGenes.strength.firstGen,
                    _fatherDragonGenes.recesive1Genes.strength.firstGen,
                    _fatherDragonGenes.recesive2Genes.strength.firstGen
                ),
                // second gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.strength.secondGen,
                    _motherDragonGenes.recesive1Genes.strength.secondGen,
                    _motherDragonGenes.recesive2Genes.strength.secondGen,
                    _fatherDragonGenes.dominantGenes.strength.secondGen,
                    _fatherDragonGenes.recesive1Genes.strength.secondGen,
                    _fatherDragonGenes.recesive2Genes.strength.secondGen
                ),
                // third gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.strength.thirdGen,
                    _motherDragonGenes.recesive1Genes.strength.thirdGen,
                    _motherDragonGenes.recesive2Genes.strength.thirdGen,
                    _fatherDragonGenes.dominantGenes.strength.thirdGen,
                    _fatherDragonGenes.recesive1Genes.strength.thirdGen,
                    _fatherDragonGenes.recesive2Genes.strength.thirdGen
                )
            ),
            // Dexterity Genes
            Gen(
                // first gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.dexterity.firstGen,
                    _motherDragonGenes.recesive1Genes.dexterity.firstGen,
                    _motherDragonGenes.recesive2Genes.dexterity.firstGen,
                    _fatherDragonGenes.dominantGenes.dexterity.firstGen,
                    _fatherDragonGenes.recesive1Genes.dexterity.firstGen,
                    _fatherDragonGenes.recesive2Genes.dexterity.firstGen
                ),
                // second gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.dexterity.secondGen,
                    _motherDragonGenes.recesive1Genes.dexterity.secondGen,
                    _motherDragonGenes.recesive2Genes.dexterity.secondGen,
                    _fatherDragonGenes.dominantGenes.dexterity.secondGen,
                    _fatherDragonGenes.recesive1Genes.dexterity.secondGen,
                    _fatherDragonGenes.recesive2Genes.dexterity.secondGen
                ),
                // third gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.dexterity.thirdGen,
                    _motherDragonGenes.recesive1Genes.dexterity.thirdGen,
                    _motherDragonGenes.recesive2Genes.dexterity.thirdGen,
                    _fatherDragonGenes.dominantGenes.dexterity.thirdGen,
                    _fatherDragonGenes.recesive1Genes.dexterity.thirdGen,
                    _fatherDragonGenes.recesive2Genes.dexterity.thirdGen
                )
            ),
            // Spirit Genes
            Gen(
                // first gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.spirit.firstGen,
                    _motherDragonGenes.recesive1Genes.spirit.firstGen,
                    _motherDragonGenes.recesive2Genes.spirit.firstGen,
                    _fatherDragonGenes.dominantGenes.spirit.firstGen,
                    _fatherDragonGenes.recesive1Genes.spirit.firstGen,
                    _fatherDragonGenes.recesive2Genes.spirit.firstGen
                ),
                // second gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.spirit.secondGen,
                    _motherDragonGenes.recesive1Genes.spirit.secondGen,
                    _motherDragonGenes.recesive2Genes.spirit.secondGen,
                    _fatherDragonGenes.dominantGenes.spirit.secondGen,
                    _fatherDragonGenes.recesive1Genes.spirit.secondGen,
                    _fatherDragonGenes.recesive2Genes.spirit.secondGen
                ),
                // third gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.spirit.thirdGen,
                    _motherDragonGenes.recesive1Genes.spirit.thirdGen,
                    _motherDragonGenes.recesive2Genes.spirit.thirdGen,
                    _fatherDragonGenes.dominantGenes.spirit.thirdGen,
                    _fatherDragonGenes.recesive1Genes.spirit.thirdGen,
                    _fatherDragonGenes.recesive2Genes.spirit.thirdGen
                )
            ),
            // Intelligence random Genes
            Gen(
                // first gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.intelligence.firstGen,
                    _motherDragonGenes.recesive1Genes.intelligence.firstGen,
                    _motherDragonGenes.recesive2Genes.intelligence.firstGen,
                    _fatherDragonGenes.dominantGenes.intelligence.firstGen,
                    _fatherDragonGenes.recesive1Genes.intelligence.firstGen,
                    _fatherDragonGenes.recesive2Genes.intelligence.firstGen
                ),
                // second gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.intelligence.secondGen,
                    _motherDragonGenes.recesive1Genes.intelligence.secondGen,
                    _motherDragonGenes.recesive2Genes.intelligence.secondGen,
                    _fatherDragonGenes.dominantGenes.intelligence.secondGen,
                    _fatherDragonGenes.recesive1Genes.intelligence.secondGen,
                    _fatherDragonGenes.recesive2Genes.intelligence.secondGen
                ),
                // third gen
                _selectRandomGen(
                    _motherDragonGenes.dominantGenes.intelligence.thirdGen,
                    _motherDragonGenes.recesive1Genes.intelligence.thirdGen,
                    _motherDragonGenes.recesive2Genes.intelligence.thirdGen,
                    _fatherDragonGenes.dominantGenes.intelligence.thirdGen,
                    _fatherDragonGenes.recesive1Genes.intelligence.thirdGen,
                    _fatherDragonGenes.recesive2Genes.intelligence.thirdGen
                )
            )
        );

        return
            DragonGenes(
                _newDragonDominantGenes, //dominant Genes,
                _motherDragonGenes.dominantGenes, // recesive1Genes from dominant mother Genes
                _fatherDragonGenes.dominantGenes // recesive2Genes from dominant father Genes
            );
    }

    function _selectRandomGen(
        uint8[NUM_OF_ATTRIBUTES] memory _motherDominantGen,
        uint8[NUM_OF_ATTRIBUTES] memory _motherRecesive1Gen,
        uint8[NUM_OF_ATTRIBUTES] memory _motherRecesive2Gen,
        uint8[NUM_OF_ATTRIBUTES] memory _fatherDominantGen,
        uint8[NUM_OF_ATTRIBUTES] memory _fatherRecesive1Gen,
        uint8[NUM_OF_ATTRIBUTES] memory _fatherRecesive2Gen
    ) private returns (uint8[NUM_OF_ATTRIBUTES] memory) {
        uint8[NUM_OF_ATTRIBUTES] memory _candidateMotherGen;
        uint8[NUM_OF_ATTRIBUTES] memory _candidateFatherGen;

        _candidateMotherGen = _selectCandidateGen(
            _motherDominantGen, // 80%
            _motherRecesive1Gen, // 15%
            _motherRecesive2Gen // 5%
        );

        _candidateFatherGen = _selectCandidateGen(
            _fatherDominantGen, // 80%
            _fatherRecesive1Gen, // 15%
            _fatherRecesive2Gen // 5%
        );

        // 50% gen from mother & 50% gen from father
        bool isMotherGen = _randomBetween(1, 2) == 1;

        if (isMotherGen) {
            return _candidateMotherGen;
        } else {
            return _candidateFatherGen;
        }
    }

    function _selectCandidateGen(
        uint8[NUM_OF_ATTRIBUTES] memory _dominantGen,
        uint8[NUM_OF_ATTRIBUTES] memory _recesive1Gen,
        uint8[NUM_OF_ATTRIBUTES] memory _recesive2Gen
    ) private returns (uint8[NUM_OF_ATTRIBUTES] memory) {
        uint256 randomNumber = _randomBetween(1, 100);

        // dominant genes 80%
        if (randomNumber <= DOMINANT_GENES_PROBABILITY) {
            return _dominantGen;
        }

        // recesive2 genes 10%
        if (randomNumber > (100 - RECESIVE_2_GENES_PROBABILITY)) {
            return _recesive1Gen;
        }

        // recesive1 genes 10%
        return _recesive2Gen;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

import "./Dragon.sol";
import "./DragonGenetics.sol";

uint256 constant LAY_EGG_COOLDOWN = 10 minutes; // cooldown to lay a new egg
uint256 constant TIME_TO_BECOME_ADULT = 2 minutes; // time to become adult

struct newDragonData {
    uint256 motherId;
    uint256 fatherId;
    bool gender;
    uint8 color;
    DragonGenes dragonGenes;
    uint256 dragonEggId;
    uint256 readyTimeToLayAnEgg;
    address owner;
}

interface DragonEggInterface {
    function createDragonEgg(
        uint256 _motherId,
        uint256 _fatherId,
        address _owner
    ) external returns (uint256 dragonEggId);
}

contract DragonReproduction is DragonGenetics {
    DragonEggInterface dragonEggInterface;

    function _setDragonEggContractAddress(address _address) internal {
        dragonEggInterface = DragonEggInterface(_address);
    }

    function _birthNewDragon(
        dragon memory _motherDragon,
        dragon memory _fatherDragon,
        uint256 _dragonEggId,
        address _owner
    ) internal returns (newDragonData memory) {
        uint256 _readyTimeToLayAnEgg = block.timestamp + TIME_TO_BECOME_ADULT;

        bool _newDragonGender = calculateNewDragonGender();

        uint8 _newDragonColor = calculateNewDragonColor(
            _motherDragon.color,
            _fatherDragon.color
        );

        DragonGenes memory _newDragonGenes = calculateNewDragonGenes(
            _motherDragon.dragonGenes,
            _fatherDragon.dragonGenes
        );

        return
            newDragonData(
                _motherDragon.dragonId,
                _fatherDragon.dragonId,
                _newDragonGender,
                _newDragonColor,
                _newDragonGenes,
                _dragonEggId,
                _readyTimeToLayAnEgg,
                _owner
            );
    }

    function _reproduceDragons(
        dragon storage _motherDragon,
        dragon storage _fatherDragon,
        address ownerMotherDragon,
        address ownerFatherDragon
    ) internal returns (uint256[2] memory _dragonEggIds) {
        require(_motherDragon.gender == true);
        require(_fatherDragon.gender == false);

        require(_motherDragon.readyTimeToLayAnEgg <= block.timestamp);
        require(_fatherDragon.readyTimeToLayAnEgg <= block.timestamp);

        // update the mather & father readyTimeToLayAnEgg
        _motherDragon.readyTimeToLayAnEgg = block.timestamp + LAY_EGG_COOLDOWN;
        _fatherDragon.readyTimeToLayAnEgg = block.timestamp + LAY_EGG_COOLDOWN;

        // TODO: you can generate more than 1 eggs at once!
        return [
            // mother egg
            _createDragonEgg(
                _motherDragon.dragonId,
                _fatherDragon.dragonId,
                ownerMotherDragon
            ),
            // father egg
            _createDragonEgg(
                _motherDragon.dragonId,
                _fatherDragon.dragonId,
                ownerFatherDragon
            )
        ];
    }

    function _createRandomDragonEgg(address owner)
        internal
        returns (uint256 dragonEggId)
    {
        return _createDragonEgg(TIAMAT_DRAGON_ID, BAHAMUT_DRAGON_ID, owner);
    }

    function _createDragonEgg(
        uint256 motherDragonId,
        uint256 fatherDragonId,
        address owner
    ) private returns (uint256 dragonEggId) {
        return
            dragonEggInterface.createDragonEgg(
                motherDragonId,
                fatherDragonId,
                owner
            );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

contract DragonUtils {
    uint256 nonce;

    function _randomBetween(uint256 _num1, uint256 _num2)
        internal
        returns (uint256)
    {
        if (_num1 == _num2) {
            return _num1;
        }

        uint256 _max = _getMax(_num1, _num2);
        uint256 _min = _getMin(_num1, _num2);

        uint256 _modulus = _max - _min + 1;

        return
            (uint256(
                keccak256(
                    // TODO: change this unsecure random function
                    abi.encodePacked(block.difficulty, block.timestamp, nonce++)
                )
            ) % _modulus) + _min;
    }

    function _getMax(uint256 _num1, uint256 _num2)
        internal
        pure
        returns (uint256)
    {
        if (_num1 > _num2) {
            return _num1;
        }

        return _num2;
    }

    function _getMin(uint256 _num1, uint256 _num2)
        internal
        pure
        returns (uint256)
    {
        if (_num1 < _num2) {
            return _num1;
        }

        return _num2;
    }
}