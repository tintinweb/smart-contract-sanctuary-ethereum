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

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
library EnumerableSet {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/GeneScienceInterface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/GatchaItem.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/FadeAwayBunnyNFT.sol";
import "../interfaces/IPillToken.sol";

contract BreedingRouter is Ownable, Pausable, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// in Ethereum, the average block time is between 12 to 14 seconds and is evaluated after each block
    /// for calculation countDownBlock;
    uint256 public constant secondsPerBlock = 12;
    uint256 public constant maxFertility = 7;
    uint256 public constant timestampPerDay = uint256(1 days);
    uint256 public maxPillForStaking = 10000000 * 10**18;
    uint256 public totalPillClaimed = 254671655242666660000000 + 1315417591000000000000000;

    uint256 public breedCostPerDay = 600 * 10**18;
    // 33.33%
    uint256 public rentFee = 3333;
    uint256 public itemNum = 20;
    uint256 public nyanKeeCost = 10000 * 10**18;
    // config later
    uint256 public resetFerdilityCost = 10000000 * 10**18;
    // config later
    uint256 public turnOnBreedGen1Cost = 10000000 * 10**18;

    uint256 public dripRate = 4000; // same with rewardRate, 10000 = 100%
    uint256 public finalRewardBlock; // The block number when token rewarding has to end.
    uint256 public rewardPerDay = 100 * 1e18; // 100 PILL per day
    uint256 public itemEffectBlock = 50400; // 7 days with 12s each block
    uint256 public constant blockPerDay = 7200; // 1 day with 12s each block
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public itemPrice = 800 * 10**18;
    uint256 public dripCost = 400 * 1e18;
    FadeAwayBunnyNFT public nftAddress;
    GatchaItem public gatchaItem;
    IPillToken public rewardToken;
    GeneScienceInterface public geneScience;

    struct UserInfo {
        uint256 amount;
        uint256 harvestedReward;
        mapping(uint256 => uint256) itemEndBlock;
        EnumerableSet.UintSet nftIds;
        mapping(uint256 => uint256) lastRewardBlock;
    }
    mapping(address => UserInfo) private userInfo;
    //// SuicideRate in zoom 10000 -> 30% = 3000, 60% = 6000
    uint16[] public intToSuicideRate;
    struct LeaseMarket {
        // price by day
        uint256 price;
        uint256 timestampLease;
        uint256 timestampRent;
        address renter;
        address owner;
        // duration for rent
        uint256 duration;
        bool usedToBreed;
    }
    struct Breeding {
        // bunny id 1
        uint256 bunnyId1;
        // bunny id 2
        uint256 bunnyId2;
        // bunny contract
        address bunnyContract;
        // owner who breeding
        address owner;
        // owner who breeding
        address rentedBunnyOwner;
        // time give breeding
        uint256 timestampBreeding;
        // time duration for breeding
        uint256 duration;
        /// block number
        uint256 cooldownEndBlock;
        /// block number
        uint256 successRate;
        /// is use ryankee
        bool useRyanKee;
        // is Rented Bunnies.
        bool isRentedBunny;
    }

    mapping(uint256 => LeaseMarket) public tokenIdLeaseMarket;
    mapping(uint256 => Breeding) public tokenIdBreedings;
    mapping(uint256 => uint256) public idToBreedCounts;
    event Deposit(address indexed user, uint256 indexed nftId);
    event Withdraw(address indexed user, uint256 indexed nftId);
    event Harvest(address indexed user, uint256 indexed nftId, uint256 amount);
    event ApplyItem(address indexed user, uint256 indexed nftId, uint256 itemExpireBlock);

    event UserLeaseBunny(address _user, uint256 _tokenId, uint256 _price);
    event UserCancelLeaseBunny(address _user, uint256 _tokenId);
    event UserRentBunny(address _owner, address _user, uint256 _tokenId, uint256 _price, uint256 _duration);
    event UserRentExtensionBunny(address _owner, address _user, uint256 _tokenId, uint256 _price, uint256 _duration);
    event UserBreedBunny(
        address _user,
        address _rentedBunnyOwner,
        uint256 _bunnyId1,
        uint256 _bunnyId2,
        bool _isRentedBunny,
        uint256 _duration
    );
    event UserGiveBirth(address _user, uint256 _bunnyId1, uint256 _bunnyId2, uint256 _childrenBunnyId);
    event UserGatchaBunny(address _user, uint256 _bunnyId1, uint256 _itemId);
    event UserBuyGatchaItem(address _user, uint256 _itemId);

    constructor(
        IPillToken _rewardToken,
        FadeAwayBunnyNFT _nftAddress,
        GatchaItem _gatchaItem,
        uint256 _finalRewardBlock
    ) {
        rewardToken = _rewardToken;
        nftAddress = _nftAddress;
        gatchaItem = _gatchaItem;
        finalRewardBlock = _finalRewardBlock;
    }

    /// @dev Update the address of the genetic contract, can only be called by the Owner.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setGeneScienceAddress(address _address) external onlyOwner {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);
        require(candidateContract.isGeneScience());
        // Set the new contract address
        geneScience = candidateContract;
    }

    function setNFTAddress(FadeAwayBunnyNFT _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

    function setGatChaItem(GatchaItem _gatchaItem) external onlyOwner {
        gatchaItem = _gatchaItem;
    }

    function setRewardToken(IPillToken _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setItemNum(uint256 _itemNum) external onlyOwner {
        itemNum = _itemNum;
    }

    function getFertility(uint256 tokenId) public view returns (uint256) {
        require(tokenId >= 0, "invalid token id");
        /// bunny gen 1 have breed count = 255 util have turn on breeding
        if (idToBreedCounts[tokenId] == 255) {
            return 0;
        } else {
            return maxFertility.sub(idToBreedCounts[tokenId]);
        }
    }

    function configCost(
        uint256 _breedCostPerDay,
        uint256 _dripCost,
        uint256 _nyankeeCost,
        uint256 _gatchaItemPrice,
        uint256 _resetFerdilityCost,
        uint256 _turnOnBreedGen1Cost,
        uint256 _dripRate,
        uint256 _rentFeePercen,
        uint256 _maxPillForStaking
    ) external onlyOwner {
        breedCostPerDay = _breedCostPerDay;
        dripCost = _dripCost;
        nyanKeeCost = _nyankeeCost;
        itemPrice = _gatchaItemPrice;
        resetFerdilityCost = _resetFerdilityCost;
        turnOnBreedGen1Cost = _turnOnBreedGen1Cost;
        dripRate = _dripRate;
        rentFee = _rentFeePercen;
        maxPillForStaking = _maxPillForStaking;
    }

    function resetFerdility(uint256 tokenId) external {
        (, , , , uint16 generation) = nftAddress.bunnies(tokenId);
        require(generation == 0, "that function only provice for gen 0");
        require(rewardToken.balanceOf(msg.sender) >= resetFerdilityCost, "Not enougn token for this function");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, resetFerdilityCost);
        idToBreedCounts[tokenId] = 0;
    }

    function changeGen1Ferdility(uint256 tokenId) external {
        (, , , , uint16 generation) = nftAddress.bunnies(tokenId);
        require(generation == 1, "that function only provice for gen 1");
        require(rewardToken.balanceOf(msg.sender) >= turnOnBreedGen1Cost, "Not enougn token for this function");

        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, turnOnBreedGen1Cost);
        idToBreedCounts[tokenId] = 0;
    }

    // because use bytes32 can't split it live strings
    function _parseBytes32(bytes32 gens, uint8 index) internal pure returns (bytes1 result) {
        uint8 start = (index - 1) * 8;
        assembly {
            result := shl(start, gens)
        }
    }

    function setIntToSuicideRate(uint16[] calldata suicideRates) external onlyOwner {
        intToSuicideRate = suicideRates;
    }

    function cancelLease(uint256 tokenId) external {
        LeaseMarket storage leaseMarket = tokenIdLeaseMarket[tokenId];
        require(leaseMarket.owner == msg.sender, "you are not owner");
        withdraw(tokenId);
        delete tokenIdLeaseMarket[tokenId];
        emit UserCancelLeaseBunny(msg.sender, tokenId);
    }

    function lease(uint256 tokenId, uint256 price) external {
        require(!paused(), "contract paused");
        if (!isUserStakedNft(msg.sender, tokenId)) {
            require(nftAddress.ownerOf(tokenId) == msg.sender, " you are not owners");
            // lease are still staking
            deposit(tokenId, false);
        }
        LeaseMarket memory leaseMarket;
        leaseMarket.owner = msg.sender;
        leaseMarket.price = price;
        leaseMarket.timestampLease = block.timestamp;
        leaseMarket.renter = address(0);
        tokenIdLeaseMarket[tokenId] = leaseMarket;
        emit UserLeaseBunny(msg.sender, tokenId, price);
    }

    function _rent(uint256 tokenId, uint256 durationInDay) internal {
        require(!paused(), "contract paused");
        LeaseMarket storage leaseMarket = tokenIdLeaseMarket[tokenId];
        require(rewardToken.balanceOf(msg.sender) >= leaseMarket.price.mul(durationInDay), "Not enougn token for rent");
        require(
            rewardToken.allowance(msg.sender, address(this)) >= leaseMarket.price.mul(durationInDay),
            "Please approval for contract can use Pill token"
        );
        require(leaseMarket.renter == address(0), "Bunny not available for rent");

        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, address(this), leaseMarket.price.mul(durationInDay));

        // transfer rent fee market for fee recient;
        ERC20(address(rewardToken)).safeTransfer(
            burnAddress,
            leaseMarket.price.mul(durationInDay).mul(rentFee).div(10000)
        );

        // transfer rent fee for owner;
        ERC20(address(rewardToken)).safeTransfer(
            leaseMarket.owner,
            leaseMarket.price.mul(durationInDay).sub(leaseMarket.price.mul(durationInDay).mul(rentFee).div(10000))
        );
        leaseMarket.renter = msg.sender;
        leaseMarket.timestampRent = block.timestamp;
        leaseMarket.duration = durationInDay.mul(timestampPerDay);
        emit UserRentBunny(leaseMarket.owner, msg.sender, tokenId, leaseMarket.price, leaseMarket.duration);
    }

    function _calculateBreedTime(
        bool isUseNyanKee,
        uint256 fertility1,
        uint256 fertility2,
        uint256 breedBoots1,
        uint256 breedBoots2
    ) internal pure returns (uint256) {
        /// calculate in zoom 10000, smart contract don't have decimal;
        uint256 nyanKeeRate = 0;
        if (isUseNyanKee) {
            nyanKeeRate = 1500;
        }
        uint256 group1 = uint256(10000) + (breedBoots1 + breedBoots2).div(2);
        uint256 group2 = ((fertility1.mul(10000) + fertility2.mul(10000)).mul(30000)).div(10000);
        uint256 group3 = 720000 - group2;
        uint256 group4 = group3.mul(10000).div(group1);
        uint256 breedTimeInDay = uint256(10000 - nyanKeeRate).mul(group4).div(10000).div(10000);
        return breedTimeInDay;
    }

    function estimateBreedTimeAndCost(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) external view returns (uint256, uint256) {
        uint256 breedingDay = _getBreedingTime(bunnyId1, bunnyId2, useNyanKee);
        if (useNyanKee) {
            return (breedingDay, breedingDay.mul(breedCostPerDay).add(nyanKeeCost));
        } else {
            return (breedingDay, breedingDay.mul(breedCostPerDay));
        }
    }

    function _calculateSuccessRate(uint256 suicideRate1, uint256 suicideRate2) internal pure returns (uint256) {
        /// calculate in zoom 10000, smart contract don't have decimal;
        uint256 successRate = (20000 - suicideRate1 - suicideRate2).mul(10000).div(20000);
        /// return sucess rate in zoom 10000;
        return successRate;
    }

    function getSuccessRate(uint256 bunnyId1, uint256 bunnyId2) public view returns (uint256) {
        /// calculate in zoom 10000, smart contract don't have decimal;
        (bytes32 gens1, , , , ) = nftAddress.bunnies(bunnyId1);
        (bytes32 gens2, , , , ) = nftAddress.bunnies(bunnyId2);

        uint256 suicideRate1 = intToSuicideRate[uint8(_parseBytes32(gens1, 3))];
        uint256 suicideRate2 = intToSuicideRate[uint8(_parseBytes32(gens2, 3))];
        uint256 successRate = _calculateSuccessRate(suicideRate1, suicideRate2);
        /// return sucess rate in zoom 10000;
        return successRate;
    }

    // breed time in day
    function _getBreedingTime(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) internal view returns (uint256) {
        (bytes32 gens1, , , , ) = nftAddress.bunnies(bunnyId1);
        (bytes32 gens2, , , , ) = nftAddress.bunnies(bunnyId2);
        // breed boots = 50% - SuicideRate
        // but get intToSuicideRate from secound pair
        uint256 breedBoots1 = 5000 - intToSuicideRate[uint8(_parseBytes32(gens1, 3))];
        uint256 breedBoots2 = 5000 - intToSuicideRate[uint8(_parseBytes32(gens2, 3))];
        uint256 fertility1 = getFertility(bunnyId1);
        uint256 fertility2 = getFertility(bunnyId2);
        /// return day in int
        uint256 breedingTimeInDay = _calculateBreedTime(useNyanKee, fertility1, fertility2, breedBoots1, breedBoots2);
        /// return breed day
        return breedingTimeInDay;
    }

    // ignore check owner of rented Bunny
    // check rented bunny valid by time and duration
    // can't breed staking bunny, just write this function for bunny in wallet
    function _breedingWithRentedBunny(
        uint256 bunnyId1,
        uint256 rentedBunnyId,
        bool useNyanKee
    ) internal returns (uint256) {
        require(!paused(), "contract paused");
        require(
            nftAddress.isApprovedForAll(msg.sender, address(this)) == true,
            "Please approval for contract can take your bunny"
        );
        require(bunnyId1 != rentedBunnyId, "need 2 bunny to breed");

        if (!isUserStakedNft(msg.sender, bunnyId1)) {
            require(nftAddress.ownerOf(bunnyId1) == msg.sender, "you are not owner of bunnies");
            nftAddress.safeTransferFrom(msg.sender, address(this), bunnyId1);
        } else {
            _stopStakingForBreeding(bunnyId1, msg.sender);
            //// staking without lease
            LeaseMarket storage userLease = tokenIdLeaseMarket[bunnyId1];
            require(userLease.owner == address(0), "bunny have been lease out");
        }

        uint256 breedTimeInDay = _getBreedingTime(bunnyId1, rentedBunnyId, useNyanKee);
        _rent(rentedBunnyId, breedTimeInDay);
        LeaseMarket storage rentedBunny = tokenIdLeaseMarket[rentedBunnyId];

        require(getFertility(bunnyId1) >= 2, "Not enough Ferdility");
        if (useNyanKee) {
            require(
                rewardToken.allowance(msg.sender, address(this)) >= nyanKeeCost,
                "Please approval for contract can take Pill token"
            );
            require(rewardToken.balanceOf(msg.sender) >= nyanKeeCost, "Not enough token for NyanKee");
            ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, nyanKeeCost);
        }
        // for test
        // uint256 breedingTime = 100;
        // uint256 pillCost = 200 * 10**18;
        uint256 breedingTime = timestampPerDay.mul(breedTimeInDay);
        uint256 pillCost = breedTimeInDay.mul(breedCostPerDay);

        require(
            rewardToken.allowance(msg.sender, address(this)) >= pillCost,
            "Please approval for contract can take Pill token"
        );

        require(rewardToken.balanceOf(msg.sender) >= pillCost, "not enough pill");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, pillCost);

        // Parent bunny descrease to 2.. rented bunny don't descrease
        idToBreedCounts[bunnyId1] = idToBreedCounts[bunnyId1] + 2;

        rentedBunny.usedToBreed = true;
        // escow bunny to contract

        _stopStakingForBreeding(rentedBunnyId, rentedBunny.owner);

        uint256 successRate = getSuccessRate(bunnyId1, rentedBunnyId);

        Breeding memory breed;
        breed.bunnyId1 = bunnyId1;
        breed.bunnyId2 = rentedBunnyId;
        breed.bunnyContract = address(nftAddress);
        breed.owner = msg.sender;
        breed.rentedBunnyOwner = rentedBunny.owner;
        breed.isRentedBunny = true;
        breed.useRyanKee = useNyanKee;
        breed.duration = breedingTime;
        breed.timestampBreeding = block.timestamp;
        /// estimate block target;
        breed.successRate = successRate;
        breed.cooldownEndBlock = block.number + breedingTime.div(secondsPerBlock);

        tokenIdBreedings[bunnyId1] = breed;

        emit UserBreedBunny(msg.sender, rentedBunny.owner, bunnyId1, rentedBunnyId, true, breedingTime);

        return bunnyId1;
    }

    // check owner of bunies
    // escow bunies to contract.
    // can use staked bunny for breed, stop staking while they breed
    function _breedingWithBunnies(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) internal returns (uint256) {
        require(!paused(), "contract paused");
        require(
            nftAddress.isApprovedForAll(msg.sender, address(this)) == true,
            "Please approval for contract can take your bunny"
        );
        require(bunnyId1 != bunnyId2, "need 2 bunny to breed");

        // escow bunny to contract
        if (!isUserStakedNft(msg.sender, bunnyId1)) {
            require(nftAddress.ownerOf(bunnyId1) == msg.sender, "you are not owner of bunnies");
            nftAddress.safeTransferFrom(msg.sender, address(this), bunnyId1);
        } else {
            //// staking without lease
            LeaseMarket storage userLease = tokenIdLeaseMarket[bunnyId1];
            require(userLease.owner == address(0), "bunny have been lease out");
            _stopStakingForBreeding(bunnyId1, msg.sender);
        }
        if (!isUserStakedNft(msg.sender, bunnyId2)) {
            require(nftAddress.ownerOf(bunnyId2) == msg.sender, "you are not owner of bunnies");
            nftAddress.safeTransferFrom(msg.sender, address(this), bunnyId2);
        } else {
            //// staking without lease
            LeaseMarket storage userLease = tokenIdLeaseMarket[bunnyId2];
            require(userLease.owner == address(0), "bunny have been lease out");
            _stopStakingForBreeding(bunnyId2, msg.sender);
        }

        if (useNyanKee) {
            require(rewardToken.balanceOf(msg.sender) >= nyanKeeCost, "Not enough token for NyanKee");
            ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, nyanKeeCost);
        }
        require(getFertility(bunnyId1) > 0, "Not enough Ferdility");
        require(getFertility(bunnyId2) > 0, "Not enough Ferdility");

        uint256 breedTimeInDay = _getBreedingTime(bunnyId1, bunnyId2, useNyanKee);
        // for test
        // uint256 breedingTime = 100;
        // uint256 pillCost = 200 * 10**18;
        uint256 breedingTime = timestampPerDay.mul(breedTimeInDay);
        uint256 pillCost = breedTimeInDay.mul(breedCostPerDay);
        require(rewardToken.balanceOf(msg.sender) >= pillCost, "not enough pill");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, pillCost);

        // inscrease Breed Count 1
        idToBreedCounts[bunnyId1] = idToBreedCounts[bunnyId1] + 1;
        idToBreedCounts[bunnyId2] = idToBreedCounts[bunnyId2] + 1;
        uint256 successRate = getSuccessRate(bunnyId1, bunnyId2);

        Breeding memory breed;
        breed.bunnyId1 = bunnyId1;
        breed.bunnyId2 = bunnyId2;
        breed.bunnyContract = address(nftAddress);
        breed.owner = msg.sender;
        breed.rentedBunnyOwner = msg.sender;
        breed.isRentedBunny = false;
        breed.useRyanKee = useNyanKee;
        breed.duration = breedingTime;
        breed.timestampBreeding = block.timestamp;
        breed.successRate = successRate;
        /// estimate block;
        breed.cooldownEndBlock = block.number + breedingTime.div(secondsPerBlock);
        tokenIdBreedings[bunnyId1] = breed;
        emit UserBreedBunny(msg.sender, msg.sender, bunnyId1, bunnyId2, false, breedingTime);

        return bunnyId1;
    }

    function breedingWithBunnies(
        uint256 bunnyId1,
        uint256 bunnyId2,
        bool useNyanKee
    ) external returns (uint256) {
        return _breedingWithBunnies(bunnyId1, bunnyId2, useNyanKee);
    }

    function gatchaBunny(uint256 tokenId, uint256[] memory itemIds) external {
        require(!paused(), "contract paused");
        require(nftAddress.ownerOf(tokenId) == msg.sender, "you are not owner of bunny");
        for (uint256 i = 0; i < itemIds.length; i++) {
            gatchaItem.safeTransferFrom(msg.sender, burnAddress, itemIds[i], 1, "0x");
            emit UserGatchaBunny(msg.sender, tokenId, itemIds[i]);
        }
    }

    function buyGatchaItem(uint256 quantity) external {
        require(!paused(), "contract paused");
        require(rewardToken.balanceOf(msg.sender) >= itemPrice * quantity, "Not enougn token for this function");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, itemPrice * quantity);
        for (uint256 i = 0; i < quantity; i++) {
            uint256 itemId = _rand(i, true);
            gatchaItem.mint(msg.sender, itemId, 1);
            emit UserBuyGatchaItem(msg.sender, itemId);
        }
    }

    function gatchaBunnyWithRandomItem(uint256 tokenId) external {
        require(!paused(), "contract paused");
        require(nftAddress.ownerOf(tokenId) == msg.sender, "you are not owner of bunny");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, itemPrice);
        uint256 itemId = _rand(tokenId, true);
        emit UserBuyGatchaItem(msg.sender, itemId);
        emit UserGatchaBunny(msg.sender, tokenId, itemId);
    }

    function breedingWithRentedBunny(
        uint256 bunnyId1,
        uint256 rentedBunnyId,
        bool useNyanKee
    ) external returns (uint256) {
        return _breedingWithRentedBunny(bunnyId1, rentedBunnyId, useNyanKee);
    }

    function giveBirth(uint256 tokenId) external returns (uint256) {
        Breeding storage breed = tokenIdBreedings[tokenId];
        require(!paused(), "contract paused");
        require(_isPregnant(tokenId), "bunny don't breeding yet");
        require(_canGiveBirth(tokenId), "can't give birth now");
        require(msg.sender == breed.owner || msg.sender == breed.rentedBunnyOwner, "You are not owner");
        (bytes32 gens1, , , , ) = nftAddress.bunnies(breed.bunnyId1);
        (bytes32 gens2, , , , ) = nftAddress.bunnies(breed.bunnyId2);

        // Call the sooper-sekret gene mixing operation.
        bytes32 childGenes = geneScience.mixGenes(uint256(gens1), uint256(gens2), breed.cooldownEndBlock - 1);
        // random 0->9999
        uint256 random = _rand(breed.bunnyId1, false);
        // suceesRate in zoom 10000 -> 80% = 8000 (1>8000 == true).
        uint256 childrenBunnyId = 0;
        if (random + 1 <= breed.successRate) {
            childrenBunnyId = nftAddress.createFadeAwayBunny(
                breed.bunnyId1,
                breed.bunnyId2,
                1,
                childGenes,
                address(this)
            );
        }
        // Make the new bunny!
        // new born bunny alway gen 1

        if (!breed.isRentedBunny) {
            // if user use 2 bunnies for breeding -> give them back.
            _depositFromBreeding(breed.owner, breed.bunnyId1);
            _depositFromBreeding(breed.owner, breed.bunnyId2);
            if (childrenBunnyId > 0) {
                idToBreedCounts[childrenBunnyId] = 255;
                _depositFromBreeding(breed.owner, childrenBunnyId);
            }
        } else {
            /// give back rented bunny for Lease Market
            _updateBunnyRentState(breed.bunnyId2, true);
            _depositFromBreeding(breed.owner, breed.bunnyId1);
            LeaseMarket storage rentedBunny = tokenIdLeaseMarket[breed.bunnyId2];
            _depositFromBreeding(rentedBunny.owner, breed.bunnyId2);
            if (childrenBunnyId > 0) {
                // bunny gen 1 can't breed
                idToBreedCounts[childrenBunnyId] = 255;
                _depositFromBreeding(breed.owner, childrenBunnyId);
            }
        }
        emit UserGiveBirth(msg.sender, breed.bunnyId1, breed.bunnyId2, childrenBunnyId);
        delete tokenIdBreedings[tokenId];
        return childrenBunnyId;
    }

    function _updateBunnyRentState(uint256 tokenId, bool isGiveBirth) internal returns (bool) {
        LeaseMarket storage rentedBunny = tokenIdLeaseMarket[tokenId];
        require(rentedBunny.timestampRent >= 0, "Bunny not yet rented");
        if (isGiveBirth) {
            //// alway give back lease market when breed done.
            rentedBunny.usedToBreed = false;
            rentedBunny.renter = address(0);
            rentedBunny.duration = 0;
            rentedBunny.timestampRent = 0;
            return true;
        } else if (rentedBunny.timestampRent + rentedBunny.duration <= block.timestamp) {
            rentedBunny.usedToBreed = false;
            rentedBunny.renter = address(0);
            rentedBunny.duration = 0;
            rentedBunny.timestampRent = 0;
            return true;
        } else {
            return false;
        }
    }

    function updateBunnyRentState(uint256 tokenId) external {
        _updateBunnyRentState(tokenId, false);
    }

    function _rand(uint256 index, bool randomItem) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number +
                        index
                )
            )
        );
        /// return rd value from 0 - 9999
        if (!randomItem) {
            return (seed - ((seed / 10000) * 10000));
        } else {
            return (seed - ((seed / itemNum) * itemNum));
        }
    }

    function _canGiveBirth(uint256 tokenId) internal view returns (bool) {
        Breeding storage breed = tokenIdBreedings[tokenId];
        if (breed.timestampBreeding == 0) return false;
        return (breed.timestampBreeding + breed.duration <= block.timestamp);
    }

    function canGiveBirth(uint256 tokenId) external view returns (bool) {
        return _canGiveBirth(tokenId);
    }

    function _isPregnant(uint256 tokenId) internal view returns (bool) {
        return tokenIdBreedings[tokenId].timestampBreeding > 0;
    }

    function isPregnant(uint256 tokenId) external view returns (bool) {
        return _isPregnant(tokenId);
    }

    // Update item effect block by the owner
    function setItemEffectBlock(uint256 _itemEffectBlock) public onlyOwner {
        itemEffectBlock = _itemEffectBlock;
    }

    // Update reward rate by the owner
    function setRewardPerDay(uint256 _rewardPerDay) public onlyOwner {
        rewardPerDay = _rewardPerDay;
    }

    // Update final reward block by the owner
    function setFinalRewardBlock(uint256 _finalRewardBlock) public onlyOwner {
        finalRewardBlock = _finalRewardBlock;
    }

    function getUserInfo(address _user) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];

        return (user.amount, user.harvestedReward);
    }

    function getApliedItemInfo(address _user, uint256 _tokenId) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.itemEndBlock[_tokenId];
    }

    //check deposited nft.
    function depositsOf(address _user) external view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_user];
        EnumerableSet.UintSet storage depositSet = user.nftIds;
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function deposit(uint256 _nftId, bool _applyItem) public {
        UserInfo storage user = userInfo[msg.sender];

        nftAddress.safeTransferFrom(address(msg.sender), address(this), _nftId);
        user.amount = user.amount.add(1);
        user.lastRewardBlock[_nftId] = block.number;
        user.nftIds.add(_nftId);
        emit Deposit(msg.sender, _nftId);
        if (_applyItem) {
            applyItem(_nftId);
        }
    }

    function _depositFromBreeding(address userAddress, uint256 _nftId) internal {
        UserInfo storage user = userInfo[userAddress];
        user.amount = user.amount.add(1);
        user.lastRewardBlock[_nftId] = block.number;
        user.nftIds.add(_nftId);
        emit Deposit(userAddress, _nftId);
    }

    function batchDeposit(uint256[] memory _nftIds) public nonReentrant {
        uint256 i;
        for (i = 0; i < _nftIds.length; i++) {
            deposit(_nftIds[i], false);
        }
    }

    function viewNftRate(uint256 _nftId) public view returns (uint16) {
        (bytes32 genes, , , , uint16 generation) = nftAddress.bunnies(_nftId);

        if (generation == 1) {
            return 10000;
        }

        uint16 earnRateInt = 10000 + (5000 - intToSuicideRate[uint8(_parseBytes32(genes, 3))]);
        return earnRateInt;
    }

    function isUserStakedNft(address _user, uint256 _nftId) public view returns (bool) {
        UserInfo storage user = userInfo[_user];

        return user.nftIds.contains(_nftId);
    }

    function viewReward(address _user, uint256 _nftId) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint16 nftRate = viewNftRate(_nftId);
        uint256 maxBlock;

        if (block.number > finalRewardBlock) {
            maxBlock = finalRewardBlock;
        } else {
            maxBlock = block.number;
        }

        if (user.lastRewardBlock[_nftId] >= maxBlock) {
            return 0;
        }

        if (user.itemEndBlock[_nftId] != 0 && user.lastRewardBlock[_nftId] <= user.itemEndBlock[_nftId]) {
            if (maxBlock <= user.itemEndBlock[_nftId]) {
                return
                    rewardPerDay.mul(maxBlock - user.lastRewardBlock[_nftId]).mul(dripRate).mul(nftRate).div(1e8).div(
                        blockPerDay
                    );
            } else {
                uint256 itemPeriod = user.itemEndBlock[_nftId] - user.lastRewardBlock[_nftId];
                uint256 normalPeriod = maxBlock - user.itemEndBlock[_nftId];
                uint256 tmpItemRate = dripRate;
                uint256 itemPeriodReward = rewardPerDay.mul(itemPeriod).mul(tmpItemRate).mul(nftRate).div(1e8).div(
                    blockPerDay
                );
                uint256 normalPeriodReward = rewardPerDay.mul(normalPeriod).mul(nftRate).div(10000).div(blockPerDay);
                return itemPeriodReward + normalPeriodReward;
            }
        } else {
            return rewardPerDay.mul(maxBlock - user.lastRewardBlock[_nftId]).mul(nftRate).div(10000).div(blockPerDay);
        }
    }

    function harvest(uint256 _nftId) public {
        require(isUserStakedNft(msg.sender, _nftId), "harvest:: this nft is not yours");
        UserInfo storage user = userInfo[msg.sender];
        uint256 reward = viewReward(msg.sender, _nftId);
        if (maxPillForStaking - totalPillClaimed == 0) {
            return;
        }
        if (maxPillForStaking - totalPillClaimed < reward) {
            reward = maxPillForStaking - totalPillClaimed;
        }
        if (reward == 0) {
            return;
        }
        totalPillClaimed = totalPillClaimed + reward;
        user.lastRewardBlock[_nftId] = block.number;
        user.harvestedReward = user.harvestedReward + reward;
        rewardToken.mint(msg.sender, reward);

        emit Harvest(msg.sender, _nftId, reward);
    }

    function _harvestForSomeOne(uint256 _nftId, address _owner) internal {
        require(isUserStakedNft(_owner, _nftId), "harvest:: this nft is not user");
        UserInfo storage user = userInfo[_owner];
        uint256 reward = viewReward(_owner, _nftId);
        if (maxPillForStaking - totalPillClaimed == 0) {
            return;
        }
        if (maxPillForStaking - totalPillClaimed < reward) {
            reward = maxPillForStaking - totalPillClaimed;
        }
        if (reward == 0) {
            return;
        }
        totalPillClaimed = totalPillClaimed + reward;

        user.lastRewardBlock[_nftId] = block.number;
        user.harvestedReward = user.harvestedReward + reward;
        rewardToken.mint(_owner, reward);

        emit Harvest(_owner, _nftId, reward);
    }

    function harvestAll() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        EnumerableSet.UintSet storage depositSet = user.nftIds;

        for (uint256 i; i < depositSet.length(); i++) {
            harvest(depositSet.at(i));
        }
    }

    function batchHarvest(uint256[] memory _nftIds) public nonReentrant {
        uint256 i;
        for (i = 0; i < _nftIds.length; i++) {
            harvest(_nftIds[i]);
        }
    }

    function batchWithdraw(uint256[] memory _nftIds) public nonReentrant {
        uint256 i;
        for (i = 0; i < _nftIds.length; i++) {
            withdraw(_nftIds[i]);
        }
    }

    function _stopStakingForBreeding(uint256 _nftId, address _owner) internal {
        require(isUserStakedNft(_owner, _nftId), "stop staking:: this nft is not yours");
        UserInfo storage user = userInfo[_owner];
        _harvestForSomeOne(_nftId, _owner);
        user.amount = user.amount.sub(1);
        user.nftIds.remove(_nftId);
        emit Withdraw(msg.sender, _nftId);
    }

    function withdraw(uint256 _nftId) public {
        require(isUserStakedNft(msg.sender, _nftId), "withdraw:: this nft is not yours");
        UserInfo storage user = userInfo[msg.sender];
        LeaseMarket storage leaseMarket = tokenIdLeaseMarket[_nftId];
        if (leaseMarket.owner == msg.sender) {
            delete tokenIdLeaseMarket[_nftId];
            emit UserCancelLeaseBunny(msg.sender, _nftId);
        }
        harvest(_nftId);
        user.amount = user.amount.sub(1);
        nftAddress.safeTransferFrom(address(this), address(msg.sender), _nftId);
        user.nftIds.remove(_nftId);
        emit Withdraw(msg.sender, _nftId);
    }

    function applyItem(uint256 _nftId) public nonReentrant {
        require(isUserStakedNft(msg.sender, _nftId), "applyItem:: this nft is not yours!");
        require(rewardToken.balanceOf(msg.sender) >= dripCost, "applyItem:: not enough Pill for DRIP cost!");
        ERC20(address(rewardToken)).safeTransferFrom(msg.sender, burnAddress, dripCost);
        UserInfo storage user = userInfo[msg.sender];
        require(block.number >= user.itemEndBlock[_nftId], "applyItem:: only 1 ecstasy can be used at a time!");
        harvest(_nftId);
        user.itemEndBlock[_nftId] = block.number + itemEffectBlock;
        emit ApplyItem(msg.sender, _nftId, block.number + itemEffectBlock);
    }

    function batchApplyItem(uint256[] memory _nftIds) public {
        for (uint8 i = 0; i < _nftIds.length; i++) {
            applyItem(_nftIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface FadeAwayBunnyNFT is IERC721 {
    function bunnies(uint256 _id)
        external
        view
        returns (
            bytes32,
            uint64,
            uint32,
            uint32,
            uint16
        );

    function createFadeAwayBunny(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        bytes32 _genes,
        address _owner
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface GatchaItem is IERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


abstract contract GeneScienceInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() public pure virtual returns (bool);

    /// @dev given genes of kitten 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public virtual returns (bytes32);

    function randomGenes(uint256 lastBlock) public virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IPillToken is IERC20 {
    function mint(address _user, uint256 _amount) external;
}