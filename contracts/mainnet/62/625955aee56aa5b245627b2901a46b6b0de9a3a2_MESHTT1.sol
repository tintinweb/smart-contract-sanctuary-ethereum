/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * 
 *    
 *   "The Mesh" by Takens Theorem
 * 
 *   Terms, conditions: Experimental, use at your own risk. Each token provided 
 *   as-is and as-available without any and all warranty. By using this contract 
 *   you accept sole responsibility for any and all transactions involving 
 *   The Mesh. 
 * 
 * 
 */

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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

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
    constructor () {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
        buffer[0] = "";
        buffer[1] = "";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4; 
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    
    // adapted from tkeber solution: https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }    
    
    // adapted from t-nicci solution https://ethereum.stackexchange.com/a/31470
    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }    
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    // nice solution: https://ethereum.stackexchange.com/questions/56319/how-to-convert-bytes32-to-string
    function toShortString(bytes32 _data) internal pure returns (string memory) {
      bytes memory _bytesContainer = new bytes(32);
      uint256 _charCount = 0;
      // loop through every element in bytes32
      for (uint256 _bytesCounter = 0; _bytesCounter < 32; _bytesCounter++) {
        bytes1 _char = bytes1(bytes32(uint256(_data) * 2 ** (8 * _bytesCounter)));
        if (_char != 0) {
          _bytesContainer[_charCount] = _char;
          _charCount++;
        }
      }
    
      bytes memory _bytesContainerTrimmed = new bytes(_charCount);
    
      for (uint256 _charCounter = 0; _charCounter < _charCount; _charCounter++) {
        _bytesContainerTrimmed[_charCounter] = _bytesContainer[_charCounter];
      }
    
      return string(_bytesContainerTrimmed);
    }    
    
}

contract externalNft {
    function balanceOf(address owner) external view returns (uint256 balance) {}
}

/**
 * @title "The Mesh" by Takens Theorem contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MESHTT1 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private MAX_SUPPLY = 72;
    function totalSupply() external view returns (uint256) {
        return MAX_SUPPLY;
    }
    string[] private romans = ["n","i","ii","iii","iv","v","vi","vii","viii","ix"];
    uint256 public lastTokenMsg = 1;         
    uint256 public lastMsgHeight = block.number;        
    uint256 public curCharity = 0;
    uint256[] private theDims = [2,36,3,24,4,18,8,8,9,9,12,12,6,6];
    string[] private theCols = ["#FF0000","#FF8B00","#E8FF00","#5DFF00","#00FF2E","#00FFB9",
                                "#00B9FF","#002EFF","#5D00FF","#E800FF","#FF008B"];
    string private svg_start = "<?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='750' width='750' viewBox='0 0 4000 4000'><rect x='0' y='0' fill='#000000' width='4000' height='4000' />";

    /************************************************
    
    NODES = functions, information about individual tokens 
    
    */
    struct Node {
        uint256 tokenMsg;
        uint256 desiredCharity; // limited to 0-7
        uint256 totMsgs;
    }
    function addNode(uint256 tokenId, uint256 charityId) private {
        Node memory node = Node(tokenId % 10, charityId, 0);
        nodes[tokenId] = node;
    }
    mapping (uint256 => Node) private nodes; // indexed 1, ..., n
    function viewNode(uint256 tokenId) external view returns (Node memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return(nodes[tokenId]);
    }
    function makePost(uint256 tokenId, uint256 msgContent) external payable {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
        require(msgContent < 10,"ERROR: message must be from 0 to 9");
        require(msg.value >= 1000000000000000 && msg.value <= 50000000000000000, 
            "ERROR: range 0.001 - 0.05 ETH required to post");

        nodes[tokenId].tokenMsg = msgContent;
        nodes[tokenId].totMsgs++;
        lastTokenMsg = tokenId;
        lastMsgHeight = block.number;
        payable(charities[curCharity].addr).transfer(msg.value); // send to charity
    }    

    /************************************************
    
    CHARITY = posting requires small donation; "The Mesh" votes on which 
    
    */
    struct Charity {
        address addr;
        string name;
        uint256 votes;
    }    
    function addCharity(address addr, string memory name) private {
        Charity memory charity = Charity(addr, name, 0);        
        charities.push(charity);
    }
    Charity[] private charities; // indexed 0, ..., n - 1 
    function viewCharity(uint256 i) external view returns (Charity memory) {
        require(i < charities.length,"ERROR: out of bounds");
        return(charities[i]);
    }
    function updateCharity() external {
        uint256 curMax = 0;
        uint256 curCharityId;
        for (uint256 i = 0; i < charities.length; i++) {
            if (charities[i].votes > curMax) {
                curMax = charities[i].votes;
                curCharityId = i;
            }
        }
        curCharity = curCharityId;
    }
    function voteCharity(uint256 tokenId, uint256 charityId) external {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
        require(charityId < charities.length,"ERROR: charity ID must be 0 - 7");

        charities[nodes[tokenId].desiredCharity].votes--;
        nodes[tokenId].desiredCharity = charityId;
        charities[charityId].votes++;        
    }    

    /************************************************
    
    SVG drawing functions (line, element, text)
    
    */
    function drawLn(uint256 x1,uint256 y1,uint256 x2,uint256 y2,string memory stroke) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<line x1='",Strings.toString(x1),
            "' y1='",Strings.toString(y1),
            "' x2='",Strings.toString(x2),
            "' y2='",Strings.toString(y2),
            "' stroke='",stroke,
            "' stroke-width='15pt' />")
        );
    }

    function drawEl(uint256 typ, uint256 x, uint256 y, uint256 sz, string memory stroke, string memory fill) private pure returns (string memory) {
        string memory output = '';
        if (typ==0) {
            output = string(abi.encodePacked(
                "<circle cx='",Strings.toString(x),
                "' cy='",Strings.toString(y),
                "' r='",Strings.toString(sz),
                "' "
            ));  
        } else {
            string memory sign_x = sz > x ? // control rects at edge
                string(abi.encodePacked('-',Strings.toString(sz - x))) :
                string(abi.encodePacked(Strings.toString(x - sz)));
            string memory sign_y = sz > y ? 
                string(abi.encodePacked('-',Strings.toString(sz - y))) :
                string(abi.encodePacked(Strings.toString(y - sz)));
            output = string(abi.encodePacked(
                "<rect x='",sign_x,
                "' y='",sign_y,
                "' width='",Strings.toString(2*sz),
                "' height='",Strings.toString(2*sz),
                "' "
            ));  
        }        
        return(string(abi.encodePacked(output,
            "fill='",fill,"' stroke='",stroke,"' stroke-width='5pt' />")));
    }

    function drawTxt(string memory txt, uint256 x, uint256 y, string memory stroke, string memory fill) private view returns (string memory) {
        return string(abi.encodePacked(
            "<text x='",Strings.toString(x),
            "' y='",Strings.toString(y),
            "' font-size='40pt' fill='",fill,
            c[1],stroke,"'>",
            txt,"</text>"
        ));
    }

    function xl(uint256 i, uint256 tokenId) private view returns (uint256) {
        uint256 ix = (lastMsgHeight + vl(1,tokenId)) % theDims.length;
        return((i-1) % theDims[ix] * 
            4000/theDims[ix] + 
            4000/theDims[ix]/2);
    }
    function yl(uint256 i, uint256 tokenId) private view returns (uint256) {
        uint256 ix = (lastMsgHeight + vl(1,tokenId)) % theDims.length;
        return((i - 1) / theDims[ix] * 
            4000/(MAX_SUPPLY/theDims[ix]) + 
            4000/(MAX_SUPPLY/theDims[ix])/2);
    }    

    /************************************************
    
    functions needed for graph
    
    */
    function getNeighbors(uint256 tokenId) public view returns (uint256, uint256, uint256[] memory, uint256[] memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        (uint256 totToks, uint256 totProjs, uint256[] memory refOwn) = getNftBalance(ownerOf(tokenId));
        uint256[] memory neighbors = new uint256[](_tokenIds.current());
        uint256 ix = 0;
        for (uint i = 1; i <= _tokenIds.current(); i++) {
            (,, uint256[] memory compOwn) = getNftBalance(ownerOf(i));
            for (uint j = 0; j < compOwn.length; j++) {
                if (compOwn[j]>0 && refOwn[j]>0) {
                    neighbors[ix] = i;
                    ix++;
                    break;
                }
            }
        }
        return(totToks, totProjs, refOwn, neighbors);
    } 

    function getNftBalance(address addr) public view returns (uint256, uint256, uint256[] memory) { 
        uint256[] memory projCounts = new uint256[](5);

        // mainnet
        projCounts[0] = externalNft(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d).balanceOf(addr);  // CryptoKitties
        projCounts[1] = externalNft(0xFBeef911Dc5821886e1dda71586d90eD28174B7d).balanceOf(addr);  // KnownOrigin
        projCounts[2] = externalNft(0x79986aF15539de2db9A5086382daEdA917A9CF0C).balanceOf(addr);  // Cryptovoxels
        projCounts[3] = externalNft(0xF3E778F839934fC819cFA1040AabaCeCBA01e049).balanceOf(addr);  // Avastars 
        projCounts[4] = externalNft(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270).balanceOf(addr);  // Art Blocks

        uint256 totToks = 0;
        uint256 totProjs = 0;
        for (uint256 i = 0; i < projCounts.length; i++){
            totToks = totToks + projCounts[i];
            if (projCounts[i] > 0) {
                totProjs = totProjs + 1;    
            }
        }

        return(totToks, totProjs, projCounts);
    }

    string ncp = 'WAIT';
    string[] private c = ['', ''];
    function setStr(string memory val) external onlyOwner {
        require(bytes(ncp).length > 0, 'ERROR: Already configured');
        if (bytes(c[0]).length == 0) {
            c[0] = val;
        } else if (bytes(c[1]).length == 0) {
            c[1] = val;
        } else if (bytes(ncp).length > 0) {
            ncp = val;        
        }
    }   

    /************************************************
    
    general functions for The Mesh
    
    */
    function renderDescription(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked("",
            "The crypto panopticon reveals.\\n\\n",
            "Last refreshed at block ", Strings.toString(block.number), "\\n\\n",
            c[0],
            Strings.toAsciiString(ownerOf(tokenId)))); 
    }

    function mintNFT_n(uint256 n) public onlyOwner {
        require(_tokenIds.current() < MAX_SUPPLY,'ERROR: minting complete');
        for (uint i = 0; i < n; i++) {
            if (_tokenIds.current() == MAX_SUPPLY) { // avoid accidental overring
                break;
            }
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            uint assignCharity = (block.number + i) % charities.length;
            charities[assignCharity].votes++;
            addNode(newItemId, assignCharity);

            _mint(msg.sender, newItemId);
        }
    }

    // raw svg
    function reveal(uint256 tokenId) public view returns (string memory) {
        require(bytes(ncp).length == 0, "ERROR: Misconfigured");
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        (uint256 totToks, uint256 totProjs,, uint256[] memory neighbors) = getNeighbors(tokenId);        
        
        string memory els = '';
        string memory theCol;        

        for (uint i = 1; i <= MAX_SUPPLY; i++) {
            theCol = string(abi.encodePacked(theCols[vl(i % (2*totProjs+1), tokenId) % theCols.length],"66"));
            els = string(abi.encodePacked(els,
                drawEl(
                    (lastMsgHeight + vl(2,tokenId)) % 2,
                    xl(i,tokenId),
                    yl(i,tokenId),
                    50+(totToks+1)*30 > 700 ? 700 : 50+(totToks+1)*30,
                    "#00000000",theCol
                )
            ));    
        }

        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i]>0 && neighbors[i]!=tokenId) {
                theCol = nodes[neighbors[i]].tokenMsg==nodes[tokenId].tokenMsg ? "#ffffffff" : "#ffffff44";
                
                els = string(abi.encodePacked(els,
                    drawEl(
                        (lastMsgHeight + vl(2,tokenId)) % 2,
                        xl(neighbors[i],tokenId),
                        yl(neighbors[i],tokenId),
                        50,"#00000000",theCol
                    ),
                    drawLn(
                        xl(tokenId,tokenId),
                        yl(tokenId,tokenId),
                        xl(neighbors[i],tokenId),
                        yl(neighbors[i],tokenId),
                        theCol
                    )                    
                ));    
            } else if (neighbors[i]==0) {
                break;
            }
        }
        
        els = string(abi.encodePacked(els,
            drawEl(
                (lastMsgHeight + vl(2,tokenId)) % 2,
                xl(tokenId,tokenId),yl(tokenId,tokenId),
                50+(totToks+1)*35 > 800 ? 800 : 50+(totToks+1)*35,
                "#00000000","#ffffff77"
            )                   
        ));
        els = string(abi.encodePacked(els,
            drawEl(
                (lastMsgHeight + vl(2,tokenId)) % 2,
                xl(tokenId,tokenId),yl(tokenId,tokenId),
                60,
                "#00000000","#000000"
            )                   
        ));
        els = string(abi.encodePacked(els,
            drawTxt(
                romans[nodes[tokenId].tokenMsg],xl(tokenId,tokenId),yl(tokenId,tokenId)+13,
                "#ffffff","#ffffff"
            )                   
        ));
        els = string(abi.encodePacked(els,
            drawEl(
                (lastMsgHeight + vl(2,tokenId)) % 2,
                xl(lastTokenMsg,tokenId),yl(lastTokenMsg,tokenId),
                60,
                "#ffffff","#00000000"
            )                   
        ));        
        
        bytes memory _img = abi.encodePacked(svg_start,els,
                 '</svg>'
             );
        return string(_img);
    }

    // pseudorandom value
    function vl(uint256 i, uint256 tokenId) private view returns (uint256) {
        bytes20 baseContent = getRandBase(tokenId);
        return uint256(uint8(baseContent[i]));
    }

    // get random base for vl and other pseudorandom functions
    function getRandBase(uint256 tokenId) private view returns (bytes20) {
        return bytes20(keccak256(abi.encodePacked(ownerOf(tokenId), tokenId, lastMsgHeight)));
    }

    // attributes json for opensea
    function makeAttributes(uint256 tokenId) public view returns (string memory) {  
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");      
        (uint256 totToks, uint256 totProjs,, uint256[] memory neighbors) = getNeighbors(tokenId);
        uint256 degree = 0;
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i]==0) {
                break;
            } else if (neighbors[i]!=tokenId) {
                degree++;
            }
        }
        string memory content = string(abi.encodePacked( 
            '{"trait_type":"Charity Vote","value":"', charities[nodes[tokenId].desiredCharity].name, '"},',
            '{"trait_type":"Degree","value":', Strings.toString(degree), '},', 
            '{"trait_type":"Message","value":"', Strings.toString(nodes[tokenId].tokenMsg), '"},',
            '{"trait_type":"Total Messages","value":', Strings.toString(nodes[tokenId].totMsgs), '},',
            '{"trait_type":"Balance","value":', Strings.toString(totToks), '},',
            '{"trait_type":"Variety","value":', Strings.toString(totProjs), '}'
        ));
        return content; 
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        bytes memory json = abi.encodePacked('{"name":"Node #',Strings.toString(tokenId),
                                            '", "description":"',renderDescription(tokenId),
                                            '", "attributes":[', makeAttributes(tokenId),']',
                                            ', "created_by":"Takens Theorem", "image":"',
                                            reveal(tokenId),
                                        '"}');
        
        return string(abi.encodePacked('data:text/plain,', json));
        
    }
    
    constructor() ERC721("The Mesh by Takens Theorem", "MESHTT1") {    
        addCharity(0x542EFf118023cfF2821b24156a507a513Fe93539, "SENS");
        addCharity(0xa18E7e408859BC1c742aA566D6aCc3F8fD5e7ffD, "Methuselah");
        addCharity(0x095f1fD53A56C01c76A2a56B7273995Ce915d8C4, "EFF");
        addCharity(0x338326660F32319E2B0Ad165fcF4a528c1994aCb, "Rainforest Foundation US");
        addCharity(0xc7464dbcA260A8faF033460622B23467Df5AEA42, "GiveDirectly");
        addCharity(0x7cF2eBb5Ca55A8bd671A020F8BDbAF07f60F26C1, "GiveWell");
        addCharity(0xD3F81260a44A1df7A7269CF66Abd9c7e4f8CdcD1, "Heifer");
        addCharity(0x633b7218644b83D57d90e7299039ebAb19698e9C, "UkraineDAO");
    }    
}