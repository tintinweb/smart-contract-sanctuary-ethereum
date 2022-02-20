/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

/* Hedron is a collection of Ethereum / PulseChain smart contracts that  *
 * build upon the HEX smart contract to provide additional functionality */

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

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

interface IHEX {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Claim(
        uint256 data0,
        uint256 data1,
        bytes20 indexed btcAddr,
        address indexed claimToAddr,
        address indexed referrerAddr
    );
    event ClaimAssist(
        uint256 data0,
        uint256 data1,
        uint256 data2,
        address indexed senderAddr
    );
    event DailyDataUpdate(uint256 data0, address indexed updaterAddr);
    event ShareRateChange(uint256 data0, uint40 indexed stakeId);
    event StakeEnd(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );
    event StakeGoodAccounting(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId,
        address indexed senderAddr
    );
    event StakeStart(
        uint256 data0,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event XfLobbyEnter(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );
    event XfLobbyExit(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );

    fallback() external payable;

    function allocatedSupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function btcAddressClaim(
        uint256 rawSatoshis,
        bytes32[] memory proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    ) external returns (uint256);

    function btcAddressClaims(bytes20) external view returns (bool);

    function btcAddressIsClaimable(
        bytes20 btcAddr,
        uint256 rawSatoshis,
        bytes32[] memory proof
    ) external view returns (bool);

    function btcAddressIsValid(
        bytes20 btcAddr,
        uint256 rawSatoshis,
        bytes32[] memory proof
    ) external pure returns (bool);

    function claimMessageMatchesSignature(
        address claimToAddr,
        bytes32 claimParamHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (bool);

    function currentDay() external view returns (uint256);

    function dailyData(uint256)
        external
        view
        returns (
            uint72 dayPayoutTotal,
            uint72 dayStakeSharesTotal,
            uint56 dayUnclaimedSatoshisTotal
        );

    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);

    function dailyDataUpdate(uint256 beforeDay) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function globalInfo() external view returns (uint256[13] memory);

    function globals()
        external
        view
        returns (
            uint72 lockedHeartsTotal,
            uint72 nextStakeSharesTotal,
            uint40 shareRate,
            uint72 stakePenaltyTotal,
            uint16 dailyDataCount,
            uint72 stakeSharesTotal,
            uint40 latestStakeId,
            uint128 claimStats
        );

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function merkleProofIsValid(bytes32 merkleLeaf, bytes32[] memory proof)
        external
        pure
        returns (bool);

    function name() external view returns (string memory);

    function pubKeyToBtcAddress(
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags
    ) external pure returns (bytes20);

    function pubKeyToEthAddress(bytes32 pubKeyX, bytes32 pubKeyY)
        external
        pure
        returns (address);

    function stakeCount(address stakerAddr) external view returns (uint256);

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external;

    function stakeLists(address, uint256)
        external
        view
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay,
            bool isAutoStake
        );

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)
        external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function xfLobby(uint256) external view returns (uint256);

    function xfLobbyEnter(address referrerAddr) external payable;

    function xfLobbyEntry(address memberAddr, uint256 entryId)
        external
        view
        returns (uint256 rawAmount, address referrerAddr);

    function xfLobbyExit(uint256 enterDay, uint256 count) external;

    function xfLobbyFlush() external;

    function xfLobbyMembers(uint256, address)
        external
        view
        returns (uint40 headIndex, uint40 tailIndex);

    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[2] memory words);

    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);
}

struct HEXDailyData {
    uint72 dayPayoutTotal;
    uint72 dayStakeSharesTotal;
    uint56 dayUnclaimedSatoshisTotal;
}

struct HEXGlobals {
    uint72 lockedHeartsTotal;
    uint72 nextStakeSharesTotal;
    uint40 shareRate;
    uint72 stakePenaltyTotal;
    uint16 dailyDataCount;
    uint72 stakeSharesTotal;
    uint40 latestStakeId;
    uint128 claimStats;
}

struct HEXStake {
    uint40 stakeId;
    uint72 stakedHearts;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
    uint16 unlockedDay;
    bool   isAutoStake;
}

struct HEXStakeMinimal {
    uint40 stakeId;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
}

struct ShareStore {
    HEXStakeMinimal stake;
    uint16          mintedDays;
    uint8           launchBonus;
    uint16          loanStart;
    uint16          loanedDays;
    uint32          interestRate;
    uint8           paymentsMade;
    bool            isLoaned;
}

struct ShareCache {
    HEXStakeMinimal _stake;
    uint256         _mintedDays;
    uint256         _launchBonus;
    uint256         _loanStart;
    uint256         _loanedDays;
    uint256         _interestRate;
    uint256         _paymentsMade;
    bool            _isLoaned;
}

address constant _hdrnSourceAddress = address(0x9d73Ced2e36C89E5d167151809eeE218a189f801);
address constant _hdrnFlowAddress   = address(0xF447BE386164dADfB5d1e7622613f289F17024D8);
uint256 constant _hdrnLaunch        = 1645833600;

contract HEXStakeInstance {
    
    IHEX       private _hx;
    address    private _creator;
    ShareStore public  share;

    /**
     * @dev Updates the HSI's internal HEX stake data.
     */
    function _stakeDataUpdate(
    )
        internal
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool   isAutoStake;
        
        (stakeId,
         stakedHearts,
         stakeShares,
         lockedDay,
         stakedDays,
         unlockedDay,
         isAutoStake
        ) = _hx.stakeLists(address(this), 0);

        share.stake.stakeId = stakeId;
        share.stake.stakeShares = stakeShares;
        share.stake.lockedDay = lockedDay;
        share.stake.stakedDays = stakedDays;
    }

    function initialize(
        address hexAddress
    ) 
        external 
    {
        require(_creator == address(0),
            "HSI: Initialization already performed");

        /* _creator is not an admin key. It is set at contsruction to be a link
           to the parent contract. In this case HSIM */
        _creator = msg.sender;

        // set HEX contract address
        _hx = IHEX(payable(hexAddress));
    }

    /**
     * @dev Creates a new HEX stake using all HEX ERC20 tokens assigned
     *      to the HSI's contract address. This is a privileged operation only
     *      HEXStakeInstanceManager.sol can call.
     * @param stakeLength Number of days the HEX ERC20 tokens will be staked.
     */
    function create(
        uint256 stakeLength
    )
        external
    {
        uint256 hexBalance = _hx.balanceOf(address(this));

        require(msg.sender == _creator,
            "HSI: Caller must be contract creator");
        require(share.stake.stakedDays == 0,
            "HSI: Creation already performed");
        require(hexBalance > 0,
            "HSI: Creation requires a non-zero HEX balance");

        _hx.stakeStart(
            hexBalance,
            stakeLength
        );

        _stakeDataUpdate();
    }

    /**
     * @dev Calls the HEX function "stakeGoodAccounting" against the
     *      HEX stake held within the HSI.
     */
    function goodAccounting(
    )
        external
    {
        require(share.stake.stakedDays > 0,
            "HSI: Creation not yet performed");

        _hx.stakeGoodAccounting(address(this), 0, share.stake.stakeId);

        _stakeDataUpdate();
    }

    /**
     * @dev Ends the HEX stake, approves the "_creator" address to transfer
     *      all HEX ERC20 tokens, and self-destructs the HSI. This is a 
     *      privileged operation only HEXStakeInstanceManager.sol can call.
     */
    function destroy(
    )
        external
    {
        require(msg.sender == _creator,
            "HSI: Caller must be contract creator");
        require(share.stake.stakedDays > 0,
            "HSI: Creation not yet performed");

        _hx.stakeEnd(0, share.stake.stakeId);
        
        uint256 hexBalance = _hx.balanceOf(address(this));

        if (_hx.approve(_creator, hexBalance)) {
            selfdestruct(payable(_creator));
        }
        else {
            revert();
        }
    }

    /**
     * @dev Updates the HSI's internal share data. This is a privileged 
     *      operation only HEXStakeInstanceManager.sol can call.
     * @param _share "ShareCache" object containing updated share data.
     */
    function update(
        ShareCache memory _share
    )
        external 
    {
        require(msg.sender == _creator,
            "HSI: Caller must be contract creator");

        share.mintedDays   = uint16(_share._mintedDays);
        share.launchBonus  = uint8 (_share._launchBonus);
        share.loanStart    = uint16(_share._loanStart);
        share.loanedDays   = uint16(_share._loanedDays);
        share.interestRate = uint32(_share._interestRate);
        share.paymentsMade = uint8 (_share._paymentsMade);
        share.isLoaned     = _share._isLoaned;
    }

    /**
     * @dev Fetches stake data from the HEX contract.
     * @return A "HEXStake" object containg the HEX stake data. 
     */
    function stakeDataFetch(
    ) 
        external
        view
        returns(HEXStake memory)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool   isAutoStake;
        
        (stakeId,
         stakedHearts,
         stakeShares,
         lockedDay,
         stakedDays,
         unlockedDay,
         isAutoStake
        ) = _hx.stakeLists(address(this), 0);

        return HEXStake(
            stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake
        );
    }
}

interface IHedron {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Claim(uint256 data, address indexed claimant, uint40 indexed stakeId);
    event LoanEnd(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId
    );
    event LoanLiquidateBid(
        uint256 data,
        address indexed bidder,
        uint40 indexed stakeId,
        uint40 indexed liquidationId
    );
    event LoanLiquidateExit(
        uint256 data,
        address indexed liquidator,
        uint40 indexed stakeId,
        uint40 indexed liquidationId
    );
    event LoanLiquidateStart(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId,
        uint40 indexed liquidationId
    );
    event LoanPayment(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId
    );
    event LoanStart(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId
    );
    event Mint(uint256 data, address indexed minter, uint40 indexed stakeId);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function calcLoanPayment(
        address borrower,
        uint256 hsiIndex,
        address hsiAddress
    ) external view returns (uint256, uint256);

    function calcLoanPayoff(
        address borrower,
        uint256 hsiIndex,
        address hsiAddress
    ) external view returns (uint256, uint256);

    function claimInstanced(
        uint256 hsiIndex,
        address hsiAddress,
        address hsiStarterAddress
    ) external;

    function claimNative(uint256 stakeIndex, uint40 stakeId)
        external
        returns (uint256);

    function currentDay() external view returns (uint256);

    function dailyDataList(uint256)
        external
        view
        returns (
            uint72 dayMintedTotal,
            uint72 dayLoanedTotal,
            uint72 dayBurntTotal,
            uint32 dayInterestRate,
            uint8 dayMintMultiplier
        );

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function hsim() external view returns (address);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function liquidationList(uint256)
        external
        view
        returns (
            uint256 liquidationStart,
            address hsiAddress,
            uint96 bidAmount,
            address liquidator,
            uint88 endOffset,
            bool isActive
        );

    function loanInstanced(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function loanLiquidate(
        address owner,
        uint256 hsiIndex,
        address hsiAddress
    ) external returns (uint256);

    function loanLiquidateBid(uint256 liquidationId, uint256 liquidationBid)
        external
        returns (uint256);

    function loanLiquidateExit(uint256 hsiIndex, uint256 liquidationId)
        external
        returns (address);

    function loanPayment(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function loanPayoff(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function loanedSupply() external view returns (uint256);

    function mintInstanced(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function mintNative(uint256 stakeIndex, uint40 stakeId)
        external
        returns (uint256);

    function name() external view returns (string memory);

    function proofOfBenevolence(uint256 amount) external;

    function shareList(uint256)
        external
        view
        returns (
            HEXStakeMinimal memory stake,
            uint16 mintedDays,
            uint8 launchBonus,
            uint16 loanStart,
            uint16 loanedDays,
            uint32 interestRate,
            uint8 paymentsMade,
            bool isLoaned
        );

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

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

abstract contract AbstractRoyalties {
    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

contract HEXStakeInstanceManager is ERC721, ERC721Enumerable, RoyaltiesV2Impl {

    using Counters for Counters.Counter;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint96 private constant _hsimRoyaltyBasis = 15; // Rarible V2 royalty basis
    string private constant _hostname = "https://api.hedron.pro/";
    string private constant _endpoint = "/hsi/";
    
    Counters.Counter private _tokenIds;
    address          private _creator;
    IHEX             private _hx;
    address          private _hxAddress;
    address          private _hsiImplementation;

    mapping(address => address[]) public  hsiLists;
    mapping(uint256 => address)   public  hsiToken;
 
    constructor(
        address hexAddress
    )
        ERC721("HEX Stake Instance", "HSI")
    {
        /* _creator is not an admin key. It is set at contsruction to be a link
           to the parent contract. In this case Hedron */
        _creator = msg.sender;

        // set HEX contract address
        _hx = IHEX(payable(hexAddress));
        _hxAddress = hexAddress;

        // create HSI implementation
        _hsiImplementation = address(new HEXStakeInstance());
        
        // initialize the HSI just in case
        HEXStakeInstance hsi = HEXStakeInstance(_hsiImplementation);
        hsi.initialize(hexAddress);
    }

    function _baseURI(
    )
        internal
        view
        virtual
        override
        returns (string memory)
    {
        string memory chainid = Strings.toString(block.chainid);
        return string(abi.encodePacked(_hostname, chainid, _endpoint));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable) 
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    event HSIStart(
        uint256         timestamp,
        address indexed hsiAddress,
        address indexed staker
    );

    event HSIEnd(
        uint256         timestamp,
        address indexed hsiAddress,
        address indexed staker
    );

    event HSITransfer(
        uint256         timestamp,
        address indexed hsiAddress,
        address indexed oldStaker,
        address indexed newStaker
    );

    event HSITokenize(
        uint256         timestamp,
        uint256 indexed hsiTokenId,
        address indexed hsiAddress,
        address indexed staker
    );

    event HSIDetokenize(
        uint256         timestamp,
        uint256 indexed hsiTokenId,
        address indexed hsiAddress,
        address indexed staker
    );

    /**
     * @dev Removes a HEX stake instance (HSI) contract address from an address mapping.
     * @param hsiList A mapped list of HSI contract addresses.
     * @param hsiIndex The index of the HSI contract address which will be removed.
     */
    function _pruneHSI(
        address[] storage hsiList,
        uint256 hsiIndex
    )
        internal
    {
        uint256 lastIndex = hsiList.length - 1;

        if (hsiIndex != lastIndex) {
            hsiList[hsiIndex] = hsiList[lastIndex];
        }

        hsiList.pop();
    }

    /**
     * @dev Loads share data from a HEX stake instance (HSI) into a "ShareCache" object.
     * @param hsi A HSI contract object from which share data will be loaded.
     * @return "ShareCache" object containing the loaded share data.
     */
    function _hsiLoad(
        HEXStakeInstance hsi
    ) 
        internal
        view
        returns (ShareCache memory)
    {
        HEXStakeMinimal memory stake;
        uint16                 mintedDays;
        uint8                  launchBonus;
        uint16                 loanStart;
        uint16                 loanedDays;
        uint32                 interestRate;
        uint8                  paymentsMade;
        bool                   isLoaned;

        (stake,
         mintedDays,
         launchBonus,
         loanStart,
         loanedDays,
         interestRate,
         paymentsMade,
         isLoaned) = hsi.share();

        return ShareCache(
            stake,
            mintedDays,
            launchBonus,
            loanStart,
            loanedDays,
            interestRate,
            paymentsMade,
            isLoaned
        );
    }

    // Internal NFT Marketplace Glue

    /** @dev Sets the Rarible V2 royalties on a specific token
     *  @param tokenId Unique ID of the HSI NFT token.
     */
    function _setRoyalties(
        uint256 tokenId
    )
        internal
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _hsimRoyaltyBasis;
        _royalties[0].account = payable(_hdrnFlowAddress);
        _saveRoyalties(tokenId, _royalties);
    }

    /**
     * @dev Retreives the number of HSI elements in an addresses HSI list.
     * @param user Address to retrieve the HSI list for.
     * @return Number of HSI elements found within the HSI list.
     */
    function hsiCount(
        address user
    )
        public
        view
        returns (uint256)
    {
        return hsiLists[user].length;
    }

    /**
     * @dev Wrapper function for hsiCount to allow HEX based applications to pull stake data.
     * @param user Address to retrieve the HSI list for.
     * @return Number of HSI elements found within the HSI list. 
     */
    function stakeCount(
        address user
    )
        external
        view
        returns (uint256)
    {
        return hsiCount(user);
    }

    /**
     * @dev Wrapper function for hsiLists to allow HEX based applications to pull stake data.
     * @param user Address to retrieve the HSI list for.
     * @param hsiIndex The index of the HSI contract address which will returned. 
     * @return "HEXStake" object containing HEX stake data. 
     */
    function stakeLists(
        address user,
        uint256 hsiIndex
    )
        external
        view
        returns (HEXStake memory)
    {
        address[] storage hsiList = hsiLists[user];

        HEXStakeInstance hsi = HEXStakeInstance(hsiList[hsiIndex]);

        return hsi.stakeDataFetch();
    }

    /**
     * @dev Creates a new HEX stake instance (HSI), transfers HEX ERC20 tokens to the
     *      HSI's contract address, and calls the "initialize" function.
     * @param amount Number of HEX ERC20 tokens to be staked.
     * @param length Number of days the HEX ERC20 tokens will be staked.
     * @return Address of the newly created HSI contract.
     */
    function hexStakeStart (
        uint256 amount,
        uint256 length
    )
        external
        returns (address)
    {
        require(amount <= _hx.balanceOf(msg.sender),
            "HSIM: Insufficient HEX to facilitate stake");

        address[] storage hsiList = hsiLists[msg.sender];

        address hsiAddress = Clones.clone(_hsiImplementation);
        HEXStakeInstance hsi = HEXStakeInstance(hsiAddress);
        hsi.initialize(_hxAddress);

        hsiList.push(hsiAddress);
        uint256 hsiIndex = hsiList.length - 1;

        require(_hx.transferFrom(msg.sender, hsiAddress, amount),
            "HSIM: HEX transfer from message sender to HSIM failed");

        hsi.create(length);

        IHedron hedron = IHedron(_creator);
        hedron.claimInstanced(hsiIndex, hsiAddress, msg.sender);

        emit HSIStart(block.timestamp, hsiAddress, msg.sender);

        return hsiAddress;
    }

    /**
     * @dev Calls the HEX stake instance (HSI) function "destroy", transfers HEX ERC20 tokens
     *      from the HSI's contract address to the senders address.
     * @param hsiIndex Index of the HSI contract's address in the caller's HSI list.
     * @param hsiAddress Address of the HSI contract in which to call the "destroy" function.
     * @return Amount of HEX ERC20 tokens awarded via ending the HEX stake.
     */
    function hexStakeEnd (
        uint256 hsiIndex,
        address hsiAddress
    )
        external
        returns (uint256)
    {
        address[] storage hsiList = hsiLists[msg.sender];

        require(hsiAddress == hsiList[hsiIndex],
            "HSIM: HSI index address mismatch");

        HEXStakeInstance hsi = HEXStakeInstance(hsiAddress);
        ShareCache memory share = _hsiLoad(hsi);

        require (share._isLoaned == false,
            "HSIM: Cannot call stakeEnd against a loaned stake");

        hsi.destroy();

        emit HSIEnd(block.timestamp, hsiAddress, msg.sender);

        uint256 hsiBalance = _hx.balanceOf(hsiAddress);

        if (hsiBalance > 0) {
            require(_hx.transferFrom(hsiAddress, msg.sender, hsiBalance),
                "HSIM: HEX transfer from HSI failed");
        }

        _pruneHSI(hsiList, hsiIndex);

        return hsiBalance;
    }

    /**
     * @dev Converts a HEX stake instance (HSI) contract address mapping into a
     *      HSI ERC721 token.
     * @param hsiIndex Index of the HSI contract's address in the caller's HSI list.
     * @param hsiAddress Address of the HSI contract to be converted.
     * @return Token ID of the newly minted HSI ERC721 token.
     */
    function hexStakeTokenize (
        uint256 hsiIndex,
        address hsiAddress
    )
        external
        returns (uint256)
    {
        address[] storage hsiList = hsiLists[msg.sender];

        require(hsiAddress == hsiList[hsiIndex],
            "HSIM: HSI index address mismatch");

        HEXStakeInstance hsi = HEXStakeInstance(hsiAddress);
        ShareCache memory share = _hsiLoad(hsi);

        require (share._isLoaned == false,
            "HSIM: Cannot tokenize a loaned stake");

        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
         hsiToken[newTokenId] = hsiAddress;

        _setRoyalties(newTokenId);

        _pruneHSI(hsiList, hsiIndex);

        emit HSITokenize(
            block.timestamp,
            newTokenId,
            hsiAddress,
            msg.sender
        );

        return newTokenId;
    }

    /**
     * @dev Converts a HEX stake instance (HSI) ERC721 token into an address mapping.
     * @param tokenId ID of the HSI ERC721 token to be converted.
     * @return Address of the detokenized HSI contract.
     */
    function hexStakeDetokenize (
        uint256 tokenId
    )
        external
        returns (address)
    {
        require(ownerOf(tokenId) == msg.sender,
            "HSIM: Detokenization requires token ownership");

        address hsiAddress = hsiToken[tokenId];
        address[] storage hsiList = hsiLists[msg.sender];

        hsiList.push(hsiAddress);
        hsiToken[tokenId] = address(0);

        _burn(tokenId);

        emit HSIDetokenize(
            block.timestamp,
            tokenId, 
            hsiAddress,
            msg.sender
        );

        return hsiAddress;
    }

    /**
     * @dev Updates the share data of a HEX stake instance (HSI) contract.
     *      This is a pivileged operation only Hedron.sol can call.
     * @param holder Address of the HSI contract owner.
     * @param hsiIndex Index of the HSI contract's address in the holder's HSI list.
     * @param hsiAddress Address of the HSI contract to be updated.
     * @param share "ShareCache" object containing updated share data.
     */
    function hsiUpdate (
        address holder,
        uint256 hsiIndex,
        address hsiAddress,
        ShareCache memory share
    )
        external
    {
        require(msg.sender == _creator,
            "HSIM: Caller must be contract creator");

        address[] storage hsiList = hsiLists[holder];

        require(hsiAddress == hsiList[hsiIndex],
            "HSIM: HSI index address mismatch");

        HEXStakeInstance hsi = HEXStakeInstance(hsiAddress);
        hsi.update(share);
    }

    /**
     * @dev Transfers ownership of a HEX stake instance (HSI) contract to a new address.
     *      This is a pivileged operation only Hedron.sol can call. End users can use
     *      the NFT tokenize / detokenize to handle HSI transfers.
     * @param currentHolder Address to transfer the HSI contract from.
     * @param hsiIndex Index of the HSI contract's address in the currentHolder's HSI list.
     * @param hsiAddress Address of the HSI contract to be transfered.
     * @param newHolder Address to transfer to HSI contract to.
     */
    function hsiTransfer (
        address currentHolder,
        uint256 hsiIndex,
        address hsiAddress,
        address newHolder
    )
        external
    {
        require(msg.sender == _creator,
            "HSIM: Caller must be contract creator");

        address[] storage hsiListCurrent = hsiLists[currentHolder];
        address[] storage hsiListNew = hsiLists[newHolder];

        require(hsiAddress == hsiListCurrent[hsiIndex],
            "HSIM: HSI index address mismatch");

        hsiListNew.push(hsiAddress);
        _pruneHSI(hsiListCurrent, hsiIndex);

        emit HSITransfer(
                    block.timestamp,
                    hsiAddress,
                    currentHolder,
                    newHolder
                );
    }

    // External NFT Marketplace Glue

    /**
     * @dev Implements ERC2981 royalty functionality. We just read the royalty data from
     *      the Rarible V2 implementation. 
     * @param tokenId Unique ID of the HSI NFT token.
     * @param salePrice Price the HSI NFT token was sold for.
     * @return receiver address to send the royalties to as well as the royalty amount.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[tokenId];
        
        if (_royalties.length > 0) {
            return (_royalties[0].account, (salePrice * _royalties[0].value) / 10000);
        }

        return (address(0), 0);
    }

    /**
     * @dev returns _hdrnFlowAddress, needed for some NFT marketplaces. This is not
     *       an admin key.
     * @return _hdrnFlowAddress
     */
    function owner(
    )
        external
        pure
        returns (address) 
    {
        return _hdrnFlowAddress;
    }

    /**
     * @dev Adds Rarible V2 and ERC2981 interface support.
     * @param interfaceId Unique contract interface identifier.
     * @return True if the interface is supported, false if not.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}

contract Hedron is ERC20 {

    using Counters for Counters.Counter;

    struct DailyDataStore {
        uint72 dayMintedTotal;
        uint72 dayLoanedTotal;
        uint72 dayBurntTotal;
        uint32 dayInterestRate;
        uint8  dayMintMultiplier;
    }

    struct DailyDataCache {
        uint256 _dayMintedTotal;
        uint256 _dayLoanedTotal;
        uint256 _dayBurntTotal;
        uint256 _dayInterestRate;
        uint256 _dayMintMultiplier;
    }

    struct LiquidationStore{
        uint256 liquidationStart;
        address hsiAddress;
        uint96  bidAmount;
        address liquidator;
        uint88  endOffset;
        bool    isActive;
    }

    struct LiquidationCache {
        uint256 _liquidationStart;
        address _hsiAddress;
        uint256 _bidAmount;
        address _liquidator;
        uint256 _endOffset;
        bool    _isActive;
    }

    uint256 constant private _hdrnLaunchDays             = 100;     // length of the launch phase bonus in Hedron days
    uint256 constant private _hdrnLoanInterestResolution = 1000000; // loan interest decimal resolution
    uint256 constant private _hdrnLoanInterestDivisor    = 2;       // relation of Hedron's interest rate to HEX's interest rate
    uint256 constant private _hdrnLoanPaymentWindow      = 30;      // how many Hedron days to roll into a single payment
    uint256 constant private _hdrnLoanDefaultThreshold   = 90;      // how many Hedron days before loan liquidation is allowed
   
    IHEX                                   private _hx;
    uint256                                private _hxLaunch;
    HEXStakeInstanceManager                private _hsim;
    Counters.Counter                       private _liquidationIds;
    address                                public  hsim;
    mapping(uint256 => ShareStore)         public  shareList;
    mapping(uint256 => DailyDataStore)     public  dailyDataList;
    mapping(uint256 => LiquidationStore)   public  liquidationList;
    uint256                                public  loanedSupply;

    constructor(
        address hexAddress,
        uint256 hexLaunch
    )
        ERC20("Hedron", "HDRN")
    {
        // set HEX contract address and launch time
        _hx = IHEX(payable(hexAddress));
        _hxLaunch = hexLaunch;

        // initialize HEX stake instance manager
        hsim = address(new HEXStakeInstanceManager(hexAddress));
        _hsim = HEXStakeInstanceManager(hsim);
    }

    function decimals()
        public
        view
        virtual
        override
        returns (uint8) 
    {
        return 9;
    }
    
    // Hedron Events

    event Claim(
        uint256         data,
        address indexed claimant,
        uint40  indexed stakeId
    );

    event Mint(
        uint256         data,
        address indexed minter,
        uint40  indexed stakeId
    );

    event LoanStart(
        uint256         data,
        address indexed borrower,
        uint40  indexed stakeId
    );

    event LoanPayment(
        uint256         data,
        address indexed borrower,
        uint40  indexed stakeId
    );

    event LoanEnd(
        uint256         data,
        address indexed borrower,
        uint40  indexed stakeId
    );

    event LoanLiquidateStart(
        uint256         data,
        address indexed borrower,
        uint40  indexed stakeId,
        uint40  indexed liquidationId
    );

    event LoanLiquidateBid(
        uint256         data,
        address indexed bidder,
        uint40  indexed stakeId,
        uint40  indexed liquidationId
    );

    event LoanLiquidateExit(
        uint256         data,
        address indexed liquidator,
        uint40  indexed stakeId,
        uint40  indexed liquidationId
    );

    // Hedron Private Functions

    function _emitClaim(
        uint40  stakeId,
        uint256 stakeShares,
        uint256 launchBonus
    )
        private
    {
        emit Claim(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72 (stakeShares)) << 40)
                |  (uint256(uint144(launchBonus)) << 112),
            msg.sender,
            stakeId
        );
    }

    function _emitMint(
        ShareCache memory share,
        uint256 payout
    )
        private
    {
        emit Mint(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72 (share._stake.stakeShares)) << 40)
                |  (uint256(uint16 (share._mintedDays))        << 112)
                |  (uint256(uint8  (share._launchBonus))       << 128)
                |  (uint256(uint120(payout))                   << 136),
            msg.sender,
            share._stake.stakeId
        );
    }

    function _emitLoanStart(
        ShareCache memory share,
        uint256 borrowed
    )
        private
    {
        emit LoanStart(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(share._stake.stakeShares)) << 40)
                |  (uint256(uint16(share._loanedDays))        << 112)
                |  (uint256(uint32(share._interestRate))      << 128)
                |  (uint256(uint96(borrowed))                 << 160),
            msg.sender,
            share._stake.stakeId
        );
    }

    function _emitLoanPayment(
        ShareCache memory share,
        uint256 payment
    )
        private
    {
        emit LoanPayment(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(share._stake.stakeShares)) << 40)
                |  (uint256(uint16(share._loanedDays))        << 112)
                |  (uint256(uint32(share._interestRate))      << 128)
                |  (uint256(uint8 (share._paymentsMade))      << 160)
                |  (uint256(uint88(payment))                  << 168),
            msg.sender,
            share._stake.stakeId
        );
    }

    function _emitLoanEnd(
        ShareCache memory share,
        uint256 payoff
    )
        private
    {
        emit LoanEnd(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(share._stake.stakeShares)) << 40)
                |  (uint256(uint16(share._loanedDays))        << 112)
                |  (uint256(uint32(share._interestRate))      << 128)
                |  (uint256(uint8 (share._paymentsMade))      << 160)
                |  (uint256(uint88(payoff))                   << 168),
            msg.sender,
            share._stake.stakeId
        );
    }

    function _emitLoanLiquidateStart(
        ShareCache memory share,
        uint40  liquidationId,
        address borrower,
        uint256 startingBid
    )
        private
    {
        emit LoanLiquidateStart(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(share._stake.stakeShares)) << 40)
                |  (uint256(uint16(share._loanedDays))        << 112)
                |  (uint256(uint32(share._interestRate))      << 128)
                |  (uint256(uint8 (share._paymentsMade))      << 160)
                |  (uint256(uint88(startingBid))              << 168),
            borrower,
            share._stake.stakeId,
            liquidationId
        );
    }

    function _emitLoanLiquidateBid(
        uint40  stakeId,
        uint40  liquidationId,
        uint256 bidAmount
    )
        private
    {
        emit LoanLiquidateBid(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint216(bidAmount)) << 40),
            msg.sender,
            stakeId,
            liquidationId
        );
    }

    function _emitLoanLiquidateExit(
        uint40  stakeId,
        uint40  liquidationId,
        address liquidator,
        uint256 finalBid
    )
        private
    {
        emit LoanLiquidateExit(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint216(finalBid)) << 40),
            liquidator,
            stakeId,
            liquidationId
        );
    }

    // HEX Internal Functions

    /**
     * @dev Calculates the current HEX day.
     * @return Number representing the current HEX day.
     */
    function _hexCurrentDay()
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - _hxLaunch) / 1 days;
    }
    
    /**
     * @dev Loads HEX daily data values from the HEX contract into a "HEXDailyData" object.
     * @param hexDay The HEX day to obtain daily data for.
     * @return "HEXDailyData" object containing the daily data values returned by the HEX contract.
     */
    function _hexDailyDataLoad(
        uint256 hexDay
    )
        internal
        view
        returns (HEXDailyData memory)
    {
        uint72 dayPayoutTotal;
        uint72 dayStakeSharesTotal;
        uint56 dayUnclaimedSatoshisTotal;

        (dayPayoutTotal,
         dayStakeSharesTotal,
         dayUnclaimedSatoshisTotal) = _hx.dailyData(hexDay);

        return HEXDailyData(
            dayPayoutTotal,
            dayStakeSharesTotal,
            dayUnclaimedSatoshisTotal
        );

    }

    /**
     * @dev Loads HEX global values from the HEX contract into a "HEXGlobals" object.
     * @return "HEXGlobals" object containing the global values returned by the HEX contract.
     */
    function _hexGlobalsLoad()
        internal
        view
        returns (HEXGlobals memory)
    {
        uint72  lockedHeartsTotal;
        uint72  nextStakeSharesTotal;
        uint40  shareRate;
        uint72  stakePenaltyTotal;
        uint16  dailyDataCount;
        uint72  stakeSharesTotal;
        uint40  latestStakeId;
        uint128 claimStats;

        (lockedHeartsTotal,
         nextStakeSharesTotal,
         shareRate,
         stakePenaltyTotal,
         dailyDataCount,
         stakeSharesTotal,
         latestStakeId,
         claimStats) = _hx.globals();

        return HEXGlobals(
            lockedHeartsTotal,
            nextStakeSharesTotal,
            shareRate,
            stakePenaltyTotal,
            dailyDataCount,
            stakeSharesTotal,
            latestStakeId,
            claimStats
        );
    }

    /**
     * @dev Loads HEX stake values from the HEX contract into a "HEXStake" object.
     * @param stakeIndex The index of the desired HEX stake within the sender's HEX stake list.
     * @return "HEXStake" object containing the stake values returned by the HEX contract.
     */
    function _hexStakeLoad(
        uint256 stakeIndex
    )
        internal
        view
        returns (HEXStake memory)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool   isAutoStake;
        
        (stakeId,
         stakedHearts,
         stakeShares,
         lockedDay,
         stakedDays,
         unlockedDay,
         isAutoStake) = _hx.stakeLists(msg.sender, stakeIndex);
         
         return HEXStake(
            stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake
        );
    }
    
    // Hedron Internal Functions

    /**
     * @dev Calculates the current Hedron day.
     * @return Number representing the current Hedron day.
     */
    function _currentDay()
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - _hdrnLaunch) / 1 days;
    }

    /**
     * @dev Calculates the multiplier to be used for the Launch Phase Bonus.
     * @param launchDay The current day of the Hedron launch phase.
     * @return Multiplier to use for the given launch day.
     */
    function _calcLPBMultiplier (
        uint256 launchDay
    )
        internal
        pure
        returns (uint256)
    {
        if (launchDay > 90) {
            return 100;
        }
        else if (launchDay > 80) {
            return 90;
        }
        else if (launchDay > 70) {
            return 80;
        }
        else if (launchDay > 60) {
            return 70;
        }
        else if (launchDay > 50) {
            return 60;
        }
        else if (launchDay > 40) {
            return 50;
        }
        else if (launchDay > 30) {
            return 40;
        }
        else if (launchDay > 20) {
            return 30;
        }
        else if (launchDay > 10) {
            return 20;
        }
        else if (launchDay > 0) {
            return 10;
        }

        return 0;
    }

    /**
     * @dev Calculates the number of bonus HDRN tokens to be minted in regards to minting bonuses.
     * @param multiplier The multiplier to use, increased by a factor of 10.
     * @param payout Payout to apply the multiplier towards.
     * @return Number of tokens to mint as a bonus.
     */
    function _calcBonus(
        uint256 multiplier, 
        uint256 payout
    )
        internal
        pure
        returns (uint256)
    {   
        return uint256((payout * multiplier) / 10);
    }

    /**
     * @dev Loads values from a "DailyDataStore" object into a "DailyDataCache" object.
     * @param dayStore "DailyDataStore" object to be loaded.
     * @param day "DailyDataCache" object to be populated with storage data.
     */
    function _dailyDataLoad(
        DailyDataStore storage dayStore,
        DailyDataCache memory  day
    )
        internal
        view
    {
        day._dayMintedTotal    = dayStore.dayMintedTotal;
        day._dayLoanedTotal    = dayStore.dayLoanedTotal;
        day._dayBurntTotal     = dayStore.dayBurntTotal;
        day._dayInterestRate   = dayStore.dayInterestRate;
        day._dayMintMultiplier = dayStore.dayMintMultiplier;

        if (day._dayInterestRate == 0) {
            uint256 hexCurrentDay = _hexCurrentDay();

            /* There is a very small window of time where it would be technically possible to pull
               HEX dailyData that is not yet defined. While unlikely to happen, we should prevent
               the possibility by pulling data from two days prior. This means our interest rate
               will slightly lag behind HEX's interest rate. */
            HEXDailyData memory hexDailyData         = _hexDailyDataLoad(hexCurrentDay - 2);
            HEXGlobals   memory hexGlobals           = _hexGlobalsLoad();
            uint256             hexDailyInterestRate = (hexDailyData.dayPayoutTotal * _hdrnLoanInterestResolution) / hexGlobals.lockedHeartsTotal;

            day._dayInterestRate = hexDailyInterestRate / _hdrnLoanInterestDivisor;

            /* Ideally we want a 50/50 split between loaned and minted Hedron. If less than 50% of the total supply is minted, allocate a bonus
               multiplier and scale it from 0 to 10. This is to attempt to prevent a situation where there is not enough available minted supply
               to cover loan interest. */
            if (loanedSupply > 0 && totalSupply() > 0) {
                uint256 loanedToMinted = (loanedSupply * 100) / totalSupply();
                if (loanedToMinted > 50) {
                    day._dayMintMultiplier = (loanedToMinted - 50) * 2;
                }
            }
        }
    }

    /**
     * @dev Updates a "DailyDataStore" object with values stored in a "DailyDataCache" object.
     * @param dayStore "DailyDataStore" object to be updated.
     * @param day "DailyDataCache" object with updated values.
     */
    function _dailyDataUpdate(
        DailyDataStore storage dayStore,
        DailyDataCache memory  day
    )
        internal
    {
        dayStore.dayMintedTotal    = uint72(day._dayMintedTotal);
        dayStore.dayLoanedTotal    = uint72(day._dayLoanedTotal);
        dayStore.dayBurntTotal     = uint72(day._dayBurntTotal);
        dayStore.dayInterestRate   = uint32(day._dayInterestRate);
        dayStore.dayMintMultiplier = uint8(day._dayMintMultiplier);
    }

    /**
     * @dev Loads share data from a HEX stake instance (HSI) into a "ShareCache" object.
     * @param hsi The HSI to load share data from.
     * @return "ShareCache" object containing the share data of the HSI.
     */
    function _hsiLoad(
        HEXStakeInstance hsi
    ) 
        internal
        view
        returns (ShareCache memory)
    {
        HEXStakeMinimal memory stake;

        uint16 mintedDays;
        uint8  launchBonus;
        uint16 loanStart;
        uint16 loanedDays;
        uint32 interestRate;
        uint8  paymentsMade;
        bool   isLoaned;

        (stake,
         mintedDays,
         launchBonus,
         loanStart,
         loanedDays,
         interestRate,
         paymentsMade,
         isLoaned) = hsi.share();

        return ShareCache(
            stake,
            mintedDays,
            launchBonus,
            loanStart,
            loanedDays,
            interestRate,
            paymentsMade,
            isLoaned
        );
    }

    /**
     * @dev Creates (or overwrites) a new share element in the share list.
     * @param stake "HEXStakeMinimal" object with which the share element is tied to.
     * @param mintedDays Amount of Hedron days the HEX stake has been minted against.
     * @param launchBonus The launch bonus multiplier of the share element.
     * @param loanStart The Hedron day the loan was started
     * @param loanedDays Amount of Hedron days the HEX stake has been borrowed against.
     * @param interestRate The interest rate of the loan.
     * @param paymentsMade Amount of payments made towards the loan.
     * @param isLoaned Flag used to determine if the HEX stake is currently borrowed against..
     */
    function _shareAdd(
        HEXStakeMinimal memory stake,
        uint256 mintedDays,
        uint256 launchBonus,
        uint256 loanStart,
        uint256 loanedDays,
        uint256 interestRate,
        uint256 paymentsMade,
        bool    isLoaned
    )
        internal
    {
        shareList[stake.stakeId] =
            ShareStore(
                stake,
                uint16(mintedDays),
                uint8(launchBonus),
                uint16(loanStart),
                uint16(loanedDays),
                uint32(interestRate),
                uint8(paymentsMade),
                isLoaned
            );
    }

    /**
     * @dev Creates a new liquidation element in the liquidation list.
     * @param hsiAddress Address of the HEX Stake Instance (HSI) being liquidated.
     * @param liquidator Address of the user starting the liquidation process.
     * @param liquidatorBid Bid amount (in HDRN) the user is starting the liquidation process with.
     * @return ID of the liquidation element.
     */
    function _liquidationAdd(
        address hsiAddress,
        address liquidator,
        uint256 liquidatorBid
    )
        internal
        returns (uint256)
    {
        _liquidationIds.increment();

        liquidationList[_liquidationIds.current()] =
            LiquidationStore (
                block.timestamp,
                hsiAddress,
                uint96(liquidatorBid),
                liquidator,
                uint88(0),
                true
            );

        return _liquidationIds.current();
    }
    
    /**
     * @dev Loads values from a "ShareStore" object into a "ShareCache" object.
     * @param shareStore "ShareStore" object to be loaded.
     * @param share "ShareCache" object to be populated with storage data.
     */
    function _shareLoad(
        ShareStore storage shareStore,
        ShareCache memory  share
    )
        internal
        view
    {
        share._stake        = shareStore.stake;
        share._mintedDays   = shareStore.mintedDays;
        share._launchBonus  = shareStore.launchBonus;
        share._loanStart    = shareStore.loanStart;
        share._loanedDays   = shareStore.loanedDays;
        share._interestRate = shareStore.interestRate;
        share._paymentsMade = shareStore.paymentsMade;
        share._isLoaned     = shareStore.isLoaned;
    }

    /**
     * @dev Loads values from a "LiquidationStore" object into a "LiquidationCache" object.
     * @param liquidationStore "LiquidationStore" object to be loaded.
     * @param liquidation "LiquidationCache" object to be populated with storage data.
     */
    function _liquidationLoad(
        LiquidationStore storage liquidationStore,
        LiquidationCache memory  liquidation
    ) 
        internal
        view
    {
        liquidation._liquidationStart = liquidationStore.liquidationStart;
        liquidation._endOffset        = liquidationStore.endOffset;
        liquidation._hsiAddress       = liquidationStore.hsiAddress;
        liquidation._liquidator       = liquidationStore.liquidator;
        liquidation._bidAmount        = liquidationStore.bidAmount;
        liquidation._isActive         = liquidationStore.isActive;
    }
    
    /**
     * @dev Updates a "ShareStore" object with values stored in a "ShareCache" object.
     * @param shareStore "ShareStore" object to be updated.
     * @param share "ShareCache object with updated values.
     */
    function _shareUpdate(
        ShareStore storage shareStore,
        ShareCache memory  share
    )
        internal
    {
        shareStore.stake        = share._stake;
        shareStore.mintedDays   = uint16(share._mintedDays);
        shareStore.launchBonus  = uint8(share._launchBonus);
        shareStore.loanStart    = uint16(share._loanStart);
        shareStore.loanedDays   = uint16(share._loanedDays);
        shareStore.interestRate = uint32(share._interestRate);
        shareStore.paymentsMade = uint8(share._paymentsMade);
        shareStore.isLoaned     = share._isLoaned;
    }

    /**
     * @dev Updates a "LiquidationStore" object with values stored in a "LiquidationCache" object.
     * @param liquidationStore "LiquidationStore" object to be updated.
     * @param liquidation "LiquidationCache" object with updated values.
     */
    function _liquidationUpdate(
        LiquidationStore storage liquidationStore,
        LiquidationCache memory  liquidation
    ) 
        internal
    {
        liquidationStore.endOffset  = uint48(liquidation._endOffset);
        liquidationStore.hsiAddress = liquidation._hsiAddress;
        liquidationStore.liquidator = liquidation._liquidator;
        liquidationStore.bidAmount  = uint96(liquidation._bidAmount);
        liquidationStore.isActive   = liquidation._isActive;
    }

    /**
     * @dev Attempts to match a "HEXStake" object to an existing share element within the share list.
     * @param stake "HEXStake" object to be matched.
     * @return Boolean indicating if the HEX stake was matched and it's index within the stake list as separate values.
     */
    function _shareSearch(
        HEXStake memory stake
    ) 
        internal
        view
        returns (bool, uint256)
    {
        bool stakeInShareList = false;
        uint256 shareIndex = 0;
        
        ShareCache memory share;

        _shareLoad(shareList[stake.stakeId], share);
            
        // stake matches an existing share element
        if (share._stake.stakeId     == stake.stakeId &&
            share._stake.stakeShares == stake.stakeShares &&
            share._stake.lockedDay   == stake.lockedDay &&
            share._stake.stakedDays  == stake.stakedDays)
        {
            stakeInShareList = true;
            shareIndex = stake.stakeId;
        }
            
        return(stakeInShareList, shareIndex);
    }

    // Hedron External Functions

    /**
     * @dev Returns the current Hedron day.
     * @return Current Hedron day
     */
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }

    /**
     * @dev Claims the launch phase bonus for a HEX stake instance (HSI). It also injects
     *      the HSI share data into into the shareList. This is a privileged  operation 
     *      only HEXStakeInstanceManager.sol can call.
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @param hsiStarterAddress Address of the user creating the HSI.
     */
    function claimInstanced(
        uint256 hsiIndex,
        address hsiAddress,
        address hsiStarterAddress
    )
        external
    {
        require(msg.sender == hsim,
            "HSIM: Caller must be HSIM");

        address _hsiAddress = _hsim.hsiLists(hsiStarterAddress, hsiIndex);
        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        if (_currentDay() < _hdrnLaunchDays) {
            share._launchBonus = _calcLPBMultiplier(_hdrnLaunchDays - _currentDay());
            _emitClaim(share._stake.stakeId, share._stake.stakeShares, share._launchBonus);
        }

        _hsim.hsiUpdate(hsiStarterAddress, hsiIndex, hsiAddress, share);

        _shareAdd(
            share._stake,
            share._mintedDays,
            share._launchBonus,
            share._loanStart,
            share._loanedDays,
            share._interestRate,
            share._paymentsMade,
            share._isLoaned
        );
    }
    
    /**
     * @dev Mints Hedron ERC20 (HDRN) tokens to the sender using a HEX stake instance (HSI) backing.
     *      HDRN Minted = HEX Stake B-Shares * (Days Served - Days Already Minted)
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @return Amount of HDRN ERC20 tokens minted.
     */
    function mintInstanced(
        uint256 hsiIndex,
        address hsiAddress
    ) 
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        address _hsiAddress = _hsim.hsiLists(msg.sender, hsiIndex);
        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));
        require(_hexCurrentDay() >= share._stake.lockedDay,
            "HDRN: cannot mint against a pending HEX stake");
        require(share._isLoaned == false,
            "HDRN: cannot mint against a loaned HEX stake");

        uint256 servedDays = 0;
        uint256 mintDays   = 0;
        uint256 payout     = 0;

        servedDays = _hexCurrentDay() - share._stake.lockedDay;
        
        // served days should never exceed staked days
        if (servedDays > share._stake.stakedDays) {
            servedDays = share._stake.stakedDays;
        }
        
        // remove days already minted from the payout
        mintDays = servedDays - share._mintedDays;

        // base payout
        payout = share._stake.stakeShares * mintDays;
               
        // launch phase bonus
        if (share._launchBonus > 0) {
            uint256 bonus = _calcBonus(share._launchBonus, payout);
            if (bonus > 0) {
                // send bonus copy to the source address
                _mint(_hdrnSourceAddress, bonus);
                day._dayMintedTotal += bonus;
                payout += bonus;
            }
        }
        else if (_currentDay() < _hdrnLaunchDays) {
            share._launchBonus = _calcLPBMultiplier(_hdrnLaunchDays - _currentDay());
            uint256 bonus = _calcBonus(share._launchBonus, payout);
            if (bonus > 0) {
                // send bonus copy to the source address
                _mint(_hdrnSourceAddress, bonus);
                day._dayMintedTotal += bonus;
                payout += bonus;
            }
        }

        // loan to mint ratio bonus
        if (day._dayMintMultiplier > 0) {
            uint256 bonus = _calcBonus(day._dayMintMultiplier, payout);
            if (bonus > 0) {
                // send bonus copy to the source address
                _mint(_hdrnSourceAddress, bonus);
                day._dayMintedTotal += bonus;
                payout += bonus;
            }
        }
        
        share._mintedDays += mintDays;

        // mint final payout to the sender
        if (payout > 0) {
            _mint(msg.sender, payout);

            _emitMint(
                share,
                payout
            );
        }

        day._dayMintedTotal += payout;

        // update HEX stake instance
        _hsim.hsiUpdate(msg.sender, hsiIndex, hsiAddress, share);
        _shareUpdate(shareList[share._stake.stakeId], share);

        _dailyDataUpdate(dayStore, day);

        return payout;
    }
    
    /**
     * @dev Claims the launch phase bonus for a naitve HEX stake.
     * @param stakeIndex Index of the HEX stake in sender's HEX stake list.
     *                   (see stakeLists -> HEX.sol)
     * @param stakeId ID of the HEX stake which coinsides with the index.
     * @return Number representing the launch bonus of the claimed HEX stake
     *         increased by a factor of 10 for decimal resolution.
     */
    function claimNative(
        uint256 stakeIndex,
        uint40  stakeId
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        HEXStake memory stake = _hexStakeLoad(stakeIndex);

        require(stake.stakeId == stakeId,
            "HDRN: HEX stake index id mismatch");

        bool stakeInShareList = false;
        uint256 shareIndex    = 0;
        uint256 launchBonus   = 0;
        
        // check if share element already exists in the sender's mapping
        (stakeInShareList,
         shareIndex) = _shareSearch(stake);

        require(stakeInShareList == false,
            "HDRN: HEX Stake already claimed");

        if (_currentDay() < _hdrnLaunchDays) {
            launchBonus = _calcLPBMultiplier(_hdrnLaunchDays - _currentDay());
            _emitClaim(stake.stakeId, stake.stakeShares, launchBonus);
        }

        _shareAdd(
            HEXStakeMinimal(
                stake.stakeId,
                stake.stakeShares,
                stake.lockedDay,
                stake.stakedDays
            ),
            0,
            launchBonus,
            0,
            0,
            0,
            0,
            false
        );

        return launchBonus;
    }

    /**
     * @dev Mints Hedron ERC20 (HDRN) tokens to the sender using a native HEX stake backing.
     *      HDRN Minted = HEX Stake B-Shares * (Days Served - Days Already Minted)
     * @param stakeIndex Index of the HEX stake in sender's HEX stake list (see stakeLists -> HEX.sol).
     * @param stakeId ID of the HEX stake which coinsides with the index.
     * @return Amount of HDRN ERC20 tokens minted.
     */
    function mintNative(
        uint256 stakeIndex,
        uint40 stakeId
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);
        
        HEXStake memory stake = _hexStakeLoad(stakeIndex);
    
        require(stake.stakeId == stakeId,
            "HDRN: HEX stake index id mismatch");
        require(_hexCurrentDay() >= stake.lockedDay,
            "HDRN: cannot mint against a pending HEX stake");
        
        bool stakeInShareList = false;
        uint256 shareIndex    = 0;
        uint256 servedDays    = 0;
        uint256 mintDays      = 0;
        uint256 payout        = 0;
        uint256 launchBonus   = 0;

        ShareCache memory share;
        
        // check if share element already exists in the sender's mapping
        (stakeInShareList,
         shareIndex) = _shareSearch(stake);
        
        // stake matches an existing share element
        if (stakeInShareList) {
            _shareLoad(shareList[shareIndex], share);
            
            servedDays = _hexCurrentDay() - share._stake.lockedDay;
            
            // served days should never exceed staked days
            if (servedDays > share._stake.stakedDays) {
                servedDays = share._stake.stakedDays;
            }
            
            // remove days already minted from the payout
            mintDays = servedDays - share._mintedDays;
            
            // base payout
            payout = share._stake.stakeShares * mintDays;
            
            // launch phase bonus
            if (share._launchBonus > 0) {
                uint256 bonus = _calcBonus(share._launchBonus, payout);
                if (bonus > 0) {
                    // send bonus copy to the source address
                    _mint(_hdrnSourceAddress, bonus);
                    day._dayMintedTotal += bonus;
                    payout += bonus;
                }
            }

            // loan to mint ratio bonus
            if (day._dayMintMultiplier > 0) {
                uint256 bonus = _calcBonus(day._dayMintMultiplier, payout);
                if (bonus > 0) {
                    // send bonus copy to the source address
                    _mint(_hdrnSourceAddress, bonus);
                    day._dayMintedTotal += bonus;
                    payout += bonus;
                }
            }
            
            share._mintedDays += mintDays;

            // mint final payout to the sender
            if (payout > 0) {
                _mint(msg.sender, payout);

                _emitMint(
                    share,
                    payout
                );
            }
            
            // update existing share mapping
            _shareUpdate(shareList[shareIndex], share);
        }
        
        // stake does not match an existing share element
        else {
            servedDays = _hexCurrentDay() - stake.lockedDay;
 
            // served days should never exceed staked days
            if (servedDays > stake.stakedDays) {
                servedDays = stake.stakedDays;
            }

            // base payout
            payout = stake.stakeShares * servedDays;
               
            // launch phase bonus
            if (_currentDay() < _hdrnLaunchDays) {
                launchBonus = _calcLPBMultiplier(_hdrnLaunchDays - _currentDay());
                uint256 bonus = _calcBonus(launchBonus, payout);
                if (bonus > 0) {
                    // send bonus copy to the source address
                    _mint(_hdrnSourceAddress, bonus);
                    day._dayMintedTotal += bonus;
                    payout += bonus;
                }
            }

            // loan to mint ratio bonus
            if (day._dayMintMultiplier > 0) {
                uint256 bonus = _calcBonus(day._dayMintMultiplier, payout);
                if (bonus > 0) {
                    // send bonus copy to the source address
                    _mint(_hdrnSourceAddress, bonus);
                    day._dayMintedTotal += bonus;
                    payout += bonus;
                }
            }

            // create a new share element for the sender
            _shareAdd(
                HEXStakeMinimal(
                    stake.stakeId,
                    stake.stakeShares, 
                    stake.lockedDay,
                    stake.stakedDays
                ),
                servedDays,
                launchBonus,
                0,
                0,
                0,
                0,
                false
            );

            _shareLoad(shareList[stake.stakeId], share);
            
            // mint final payout to the sender
            if (payout > 0) {
                _mint(msg.sender, payout);

                _emitMint(
                    share,
                    payout
                );
            }
        }

        day._dayMintedTotal += payout;
        
        _dailyDataUpdate(dayStore, day);

        return payout;
    }

    /**
     * @dev Calculates the payment for existing and non-existing HEX stake instance (HSI) loans.
     * @param borrower Address which has mapped ownership the HSI contract.
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @return Payment amount with principal and interest as serparate values.
     */
    function calcLoanPayment (
        address borrower,
        uint256 hsiIndex,
        address hsiAddress
    ) 
        external
        view
        returns (uint256, uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);
        
        address _hsiAddress = _hsim.hsiLists(borrower, hsiIndex);
        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        uint256 loanTermPaid      = share._paymentsMade * _hdrnLoanPaymentWindow;
        uint256 loanTermRemaining = share._loanedDays - loanTermPaid;
        uint256 principal         = 0;
        uint256 interest          = 0;

        // loan already exists
        if (share._interestRate > 0) {

            // remaining term is greater than a single payment window
            if (loanTermRemaining > _hdrnLoanPaymentWindow) {
                principal = share._stake.stakeShares * _hdrnLoanPaymentWindow;
                interest  = (principal * (share._interestRate * _hdrnLoanPaymentWindow)) / _hdrnLoanInterestResolution;
            }
            // remaing term is less than or equal to a single payment window
            else {
                principal = share._stake.stakeShares * loanTermRemaining;
                interest  = (principal * (share._interestRate * loanTermRemaining)) / _hdrnLoanInterestResolution;
            }
        }

        // loan does not exist
        else {

            // remaining term is greater than a single payment window
            if (share._stake.stakedDays > _hdrnLoanPaymentWindow) {
                principal = share._stake.stakeShares * _hdrnLoanPaymentWindow;
                interest  = (principal * (day._dayInterestRate * _hdrnLoanPaymentWindow)) / _hdrnLoanInterestResolution;
            }
            // remaing term is less than or equal to a single payment window
            else {
                principal = share._stake.stakeShares * share._stake.stakedDays;
                interest  = (principal * (day._dayInterestRate * share._stake.stakedDays)) / _hdrnLoanInterestResolution;
            }
        }

        return(principal, interest);
    }

    /**
     * @dev Calculates the full payoff for an existing HEX stake instance (HSI) loan calculating interest only up to the current Hedron day.
     * @param borrower Address which has mapped ownership the HSI contract.
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @return Payoff amount with principal and interest as separate values.
     */
    function calcLoanPayoff (
        address borrower,
        uint256 hsiIndex,
        address hsiAddress
    ) 
        external
        view
        returns (uint256, uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        address _hsiAddress = _hsim.hsiLists(borrower, hsiIndex);

        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        require (share._isLoaned == true,
            "HDRN: Cannot payoff non-existant loan");

        uint256 loanTermPaid      = share._paymentsMade * _hdrnLoanPaymentWindow;
        uint256 loanTermRemaining = share._loanedDays - loanTermPaid;
        uint256 outstandingDays   = 0;
        uint256 principal         = 0;
        uint256 interest          = 0;
        
        // user has made payments ahead of _currentDay(), no interest
        if (_currentDay() - share._loanStart < loanTermPaid) {
            principal = share._stake.stakeShares * loanTermRemaining;
        }

        // only calculate interest to the current Hedron day
        else {
            outstandingDays = _currentDay() - share._loanStart - loanTermPaid;

            if (outstandingDays > loanTermRemaining) {
                outstandingDays = loanTermRemaining;
            }

            principal = share._stake.stakeShares * loanTermRemaining;
            interest  = ((share._stake.stakeShares * outstandingDays) * (share._interestRate * outstandingDays)) / _hdrnLoanInterestResolution;
        }

        return(principal, interest);
    }

    /**
     * @dev Loans all unminted Hedron ERC20 (HDRN) tokens against a HEX stake instance (HSI).
     *      HDRN Loaned = HEX Stake B-Shares * (Days Staked - Days Already Minted)
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides the index.
     * @return Amount of HDRN ERC20 tokens borrowed.
     */
    function loanInstanced (
        uint256 hsiIndex,
        address hsiAddress
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        address _hsiAddress = _hsim.hsiLists(msg.sender, hsiIndex);

        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        require (share._isLoaned == false,
            "HDRN: HSI loan already exists");

        // only unminted days can be loaned upon
        uint256 loanDays = share._stake.stakedDays - share._mintedDays;

        require (loanDays > 0,
            "HDRN: No loanable days remaining");

        uint256 payout = share._stake.stakeShares * loanDays;

        // mint loaned tokens to the sender
        if (payout > 0) {
            share._loanStart    = _currentDay();
            share._loanedDays   = loanDays;
            share._interestRate = day._dayInterestRate;
            share._isLoaned     = true;

            _emitLoanStart(
                share,
                payout
            );

            day._dayLoanedTotal += payout;
            loanedSupply += payout;

            // update HEX stake instance
            _hsim.hsiUpdate(msg.sender, hsiIndex, hsiAddress, share);
            _shareUpdate(shareList[share._stake.stakeId], share);

            _dailyDataUpdate(dayStore, day);

            _mint(msg.sender, payout);
        }

        return payout;
    }

    /**
     * @dev Makes a single payment towards a HEX stake instance (HSI) loan.
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @return Amount of HDRN ERC20 burnt to facilitate the payment.
     */
    function loanPayment (
        uint256 hsiIndex,
        address hsiAddress
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        address _hsiAddress = _hsim.hsiLists(msg.sender, hsiIndex);

        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        require (share._isLoaned == true,
            "HDRN: Cannot pay non-existant loan");

        uint256 loanTermPaid      = share._paymentsMade * _hdrnLoanPaymentWindow;
        uint256 loanTermRemaining = share._loanedDays - loanTermPaid;
        uint256 principal         = 0;
        uint256 interest          = 0;
        bool    lastPayment       = false;

        // remaining term is greater than a single payment window
        if (loanTermRemaining > _hdrnLoanPaymentWindow) {
            principal = share._stake.stakeShares * _hdrnLoanPaymentWindow;
            interest  = (principal * (share._interestRate * _hdrnLoanPaymentWindow)) / _hdrnLoanInterestResolution;
        }
        // remaing term is less than or equal to a single payment window
        else {
            principal   = share._stake.stakeShares * loanTermRemaining;
            interest    = (principal * (share._interestRate * loanTermRemaining)) / _hdrnLoanInterestResolution;
            lastPayment = true;
        }

        require (balanceOf(msg.sender) >= (principal + interest),
            "HDRN: Insufficient balance to facilitate payment");

        // increment payment counter
        share._paymentsMade++;

        _emitLoanPayment(
            share,
            (principal + interest)
        );

        if (lastPayment == true) {
            share._loanStart    = 0;
            share._loanedDays   = 0;
            share._interestRate = 0;
            share._paymentsMade = 0;
            share._isLoaned     = false;
        }

        // update HEX stake instance
        _hsim.hsiUpdate(msg.sender, hsiIndex, hsiAddress, share);
        _shareUpdate(shareList[share._stake.stakeId], share);

        // update daily data
        day._dayBurntTotal += (principal + interest);
        _dailyDataUpdate(dayStore, day);

        // remove pricipal from global loaned supply
        loanedSupply -= principal;

        // burn payment from the sender
        _burn(msg.sender, (principal + interest));

        return(principal + interest);
    }

    /**
     * @dev Pays off a HEX stake instance (HSI) loan calculating interest only up to the current Hedron day.
     * @param hsiIndex Index of the HSI contract address in the sender's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @return Amount of HDRN ERC20 burnt to facilitate the payoff.
     */
    function loanPayoff (
        uint256 hsiIndex,
        address hsiAddress
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        address _hsiAddress = _hsim.hsiLists(msg.sender, hsiIndex);

        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        require (share._isLoaned == true,
            "HDRN: Cannot payoff non-existant loan");

        uint256 loanTermPaid      = share._paymentsMade * _hdrnLoanPaymentWindow;
        uint256 loanTermRemaining = share._loanedDays - loanTermPaid;
        uint256 outstandingDays   = 0;
        uint256 principal         = 0;
        uint256 interest          = 0;

        // user has made payments ahead of _currentDay(), no interest
        if (_currentDay() - share._loanStart < loanTermPaid) {
            principal = share._stake.stakeShares * loanTermRemaining;
        }

        // only calculate interest to the current Hedron day
        else {
            outstandingDays = _currentDay() - share._loanStart - loanTermPaid;

            if (outstandingDays > loanTermRemaining) {
                outstandingDays = loanTermRemaining;
            }

            principal = share._stake.stakeShares * loanTermRemaining;
            interest  = ((share._stake.stakeShares * outstandingDays) * (share._interestRate * outstandingDays)) / _hdrnLoanInterestResolution;
        }

        require (balanceOf(msg.sender) >= (principal + interest),
            "HDRN: Insufficient balance to facilitate payoff");

        _emitLoanEnd(
            share,
            (principal + interest)
        );

        share._loanStart    = 0;
        share._loanedDays   = 0;
        share._interestRate = 0;
        share._paymentsMade = 0;
        share._isLoaned     = false;

        // update HEX stake instance
        _hsim.hsiUpdate(msg.sender, hsiIndex, hsiAddress, share);
        _shareUpdate(shareList[share._stake.stakeId], share);

        // update daily data 
        day._dayBurntTotal += (principal + interest);
        _dailyDataUpdate(dayStore, day);

        // remove pricipal from global loaned supply
        loanedSupply -= principal;

        // burn payment from the sender
        _burn(msg.sender, (principal + interest));

        return(principal + interest);
    }

    /**
     * @dev Allows any address to liquidate a defaulted HEX stake instace (HSI) loan and start the liquidation process.
     * @param owner Address of the current HSI contract owner.
     * @param hsiIndex Index of the HSI contract address in the owner's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param hsiAddress Address of the HSI contract which coinsides with the index.
     * @return Amount of HDRN ERC20 tokens burnt as the initial liquidation bid.
     */
    function loanLiquidate (
        address owner,
        uint256 hsiIndex,
        address hsiAddress
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        address _hsiAddress = _hsim.hsiLists(owner, hsiIndex);

        require(hsiAddress == _hsiAddress,
            "HDRN: HSI index address mismatch");

        ShareCache memory share = _hsiLoad(HEXStakeInstance(hsiAddress));

        require (share._isLoaned == true,
            "HDRN: Cannot liquidate a non-existant loan");

        uint256 loanTermPaid      = share._paymentsMade * _hdrnLoanPaymentWindow;
        uint256 loanTermRemaining = share._loanedDays - loanTermPaid;
        uint256 outstandingDays   = _currentDay() - share._loanStart - loanTermPaid;
        uint256 principal         = share._stake.stakeShares * loanTermRemaining;

        require (outstandingDays >= _hdrnLoanDefaultThreshold,
            "HDRN: Cannot liquidate a loan not in default");

        if (outstandingDays > loanTermRemaining) {
            outstandingDays = loanTermRemaining;
        }

        // only calculate interest to the current Hedron day
        uint256 interest = ((share._stake.stakeShares * outstandingDays) * (share._interestRate * outstandingDays)) / _hdrnLoanInterestResolution;

        require (balanceOf(msg.sender) >= (principal + interest),
            "HDRN: Insufficient balance to facilitate liquidation");

        // zero out loan data
        share._loanStart    = 0;
        share._loanedDays   = 0;
        share._interestRate = 0;
        share._paymentsMade = 0;
        share._isLoaned     = false;

        // update HEX stake instance
        _hsim.hsiUpdate(owner, hsiIndex, hsiAddress, share);
        _shareUpdate(shareList[share._stake.stakeId], share);

        // transfer ownership of the HEX stake instance to a temporary holding address
        _hsim.hsiTransfer(owner, hsiIndex, hsiAddress, address(0));

        // create a new liquidation element
        _liquidationAdd(hsiAddress, msg.sender, (principal + interest));

        _emitLoanLiquidateStart(
            share,
            uint40(_liquidationIds.current()),
            owner,
            (principal + interest)
        );

        // remove pricipal from global loaned supply
        loanedSupply -= principal;

        // burn payment from the sender
        _burn(msg.sender, (principal + interest));

        return(principal + interest);
    }

    /**
     * @dev Allows any address to enter a bid into an active liquidation.
     * @param liquidationId ID number of the liquidation to place the bid in.
     * @param liquidationBid Amount of HDRN to bid.
     * @return Block timestamp of when the liquidation is currently scheduled to end.
     */
    function loanLiquidateBid (
        uint256 liquidationId,
        uint256 liquidationBid
    )
        external
        returns (uint256)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        LiquidationCache memory  liquidation;
        LiquidationStore storage liquidationStore = liquidationList[liquidationId];
        
        _liquidationLoad(liquidationStore, liquidation);

        require(liquidation._isActive == true,
            "HDRN: Cannot bid on invalid liquidation");

        require (balanceOf(msg.sender) >= liquidationBid,
            "HDRN: Insufficient balance to facilitate liquidation");

        require (liquidationBid > liquidation._bidAmount,
            "HDRN: Liquidation bid must be greater than current bid");

        require((block.timestamp - (liquidation._liquidationStart + liquidation._endOffset)) <= 86400,
            "HDRN: Cannot bid on expired liquidation");

        // if the bid is being placed in the last five minutes
        uint256 timestampModified = ((block.timestamp + 300) - (liquidation._liquidationStart + liquidation._endOffset));
        if (timestampModified > 86400) {
            liquidation._endOffset += (timestampModified - 86400);
        }

        // give the previous bidder back their HDRN
        _mint(liquidation._liquidator, liquidation._bidAmount);

        // new bidder takes the liquidation position
        liquidation._liquidator = msg.sender;
        liquidation._bidAmount  = liquidationBid;

        _liquidationUpdate(liquidationStore, liquidation);

        ShareCache memory share = _hsiLoad(HEXStakeInstance(liquidation._hsiAddress));

        _emitLoanLiquidateBid(
            share._stake.stakeId,
            uint40(liquidationId),
            liquidationBid
        );

        // burn the new bidders bid amount
        _burn(msg.sender, liquidationBid);

        return(
            liquidation._liquidationStart +
            liquidation._endOffset +
            86400
        );
    }

    /**
     * @dev Allows any address to exit a completed liquidation, granting control of the
            HSI to the highest bidder.
     * @param hsiIndex Index of the HSI contract address in the zero address's HSI list.
     *                 (see hsiLists -> HEXStakeInstanceManager.sol)
     * @param liquidationId ID number of the liquidation to exit.
     * @return Address of the HEX Stake Instance (HSI) contract granted to the liquidator.
     */
    function loanLiquidateExit (
        uint256 hsiIndex,
        uint256 liquidationId
    )
        external
        returns (address)
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        LiquidationStore storage liquidationStore = liquidationList[liquidationId];
        LiquidationCache memory  liquidation;

        _liquidationLoad(liquidationStore, liquidation);
        
        require(liquidation._isActive == true,
            "HDRN: Cannot exit on invalid liquidation");

        require((block.timestamp - (liquidation._liquidationStart + liquidation._endOffset)) >= 86400,
            "HDRN: Cannot exit on active liquidation");

        // transfer the held HSI to the liquidator
        _hsim.hsiTransfer(address(0), hsiIndex, liquidation._hsiAddress, liquidation._liquidator);

        // update the daily burnt total
        day._dayBurntTotal += liquidation._bidAmount;

        // deactivate liquidation, but keep data around for historical reasons.
        liquidation._isActive == false;

        ShareCache memory share = _hsiLoad(HEXStakeInstance(liquidation._hsiAddress));

        _emitLoanLiquidateExit(
            share._stake.stakeId,
            uint40(liquidationId),
            liquidation._liquidator,
            liquidation._bidAmount
        );

        _dailyDataUpdate(dayStore, day);
        _liquidationUpdate(liquidationStore, liquidation);

        return liquidation._hsiAddress;
    }

    /**
     * @dev Burns HDRN tokens from the caller's address.
     * @param amount Amount of HDRN to burn.
     */
    function proofOfBenevolence (
        uint256 amount
    )
        external
    {
        require(block.timestamp >= _hdrnLaunch,
            "HDRN: Contract not yet active");

        DailyDataCache memory  day;
        DailyDataStore storage dayStore = dailyDataList[_currentDay()];

        _dailyDataLoad(dayStore, day);

        require (balanceOf(msg.sender) >= amount,
            "HDRN: Insufficient balance to facilitate PoB");

        uint256 currentAllowance = allowance(msg.sender, address(this));

        require(currentAllowance >= amount,
            "HDRN: Burn amount exceeds allowance");
        
        day._dayBurntTotal += amount;
        _dailyDataUpdate(dayStore, day);

        unchecked {
            _approve(msg.sender, address(this), currentAllowance - amount);
        }

        _burn(msg.sender, amount);
    }
}