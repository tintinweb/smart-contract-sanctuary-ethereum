// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "./interfaces/IHadaro.sol";

contract Hadaro is IHadaro, ERC721Holder, ERC1155Receiver, ERC1155Holder {
  using SafeERC20 for ERC20;

  IResolver private resolver;
  address private admin;
  address payable private beneficiary;
  uint256 private lendingID = 1;
  uint256 private rentingID = 1;
  bool public paused = false;

  // in bps. so 100 => 1%
  uint256 public rentFee = 300;

  uint256 private constant SECONDS_IN_DAY = 86400;
  mapping(bytes32 => Lending) private lendings;
  mapping(bytes32 => Renting) private rentings;

  modifier onlyAdmin() {
    require(msg.sender == admin, "Hadaro::not admin");
    _;
  }

  modifier notPaused() {
    require(!paused, "Hadaro::paused");
    _;
  }

  constructor(
    address newResolver,
    address payable newBeneficiary,
    address newAdmin
  ) {
    ensureIsNotZeroAddr(newResolver);
    ensureIsNotZeroAddr(newBeneficiary);
    ensureIsNotZeroAddr(newAdmin);
    resolver = IResolver(newResolver);
    beneficiary = newBeneficiary;
    admin = newAdmin;
  }

  function lend(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendAmount,
    uint8[] memory maxRentDuration,
    bytes4[] memory dailyRentPrice,
    uint8[] memory paymentToken,
    bool[] memory willAutoRenew
  ) external override notPaused {
    bundleCall(
      handleLend,
      createLendCallData(
        nftStandard,
        nftAddress,
        tokenID,
        lendAmount,
        maxRentDuration,
        dailyRentPrice,
        paymentToken,
        willAutoRenew
      )
    );
  }

  function stopLend(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory _lendingID
  ) external override notPaused {
    bundleCall(
      handleStopLend,
      createActionCallData(
        nftStandard,
        nftAddress,
        tokenID,
        _lendingID,
        new uint256[](0)
      )
    );
  }

  function rent(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory _lendingID,
    uint8[] memory rentDuration,
    uint256[] memory rentAmount
  ) external payable override notPaused {
    bundleCall(
      handleRent,
      createRentCallData(
        nftStandard,
        nftAddress,
        tokenID,
        _lendingID,
        rentDuration,
        rentAmount
      )
    );
  }

  function stopRent(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory _lendingID,
    uint256[] memory _rentingID
  ) external override notPaused {
    bundleCall(
      handleStopRent,
      createActionCallData(
        nftStandard,
        nftAddress,
        tokenID,
        _lendingID,
        _rentingID
      )
    );
  }

  function claimRent(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory _lendingID,
    uint256[] memory _rentingID
  ) external override notPaused {
    bundleCall(
      handleClaimRent,
      createActionCallData(
        nftStandard,
        nftAddress,
        tokenID,
        _lendingID,
        _rentingID
      )
    );
  }

  //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
  // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

  function handleLend(IHadaro.CallData memory cd) private {
    for (uint256 i = cd.left; i < cd.right; i++) {
      ensureIsLendable(cd, i);

      bytes32 identifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], lendingID)
      );

      IHadaro.Lending storage lending = lendings[identifier];

      ensureIsNull(lending);
      ensureTokenNotSentinel(uint8(cd.paymentToken[i]));

      bool is721 = cd.nftStandard[i] == IHadaro.NFTStandard.E721;
      uint16 _lendAmount = uint16(cd.lendAmount[i]);

      if (is721)
        require(_lendAmount == 1, "Hadaro::lendAmount should be equal to 1");

      lendings[identifier] = IHadaro.Lending({
        nftStandard: cd.nftStandard[i],
        lenderAddress: payable(msg.sender),
        maxRentDuration: cd.maxRentDuration[i],
        dailyRentPrice: cd.dailyRentPrice[i],
        lendAmount: _lendAmount,
        availableAmount: _lendAmount,
        paymentToken: cd.paymentToken[i],
        willAutoRenew: cd.willAutoRenew[i]
      });

      emit IHadaro.Lend(
        is721,
        msg.sender,
        cd.nftAddress[cd.left],
        cd.tokenID[i],
        lendingID,
        cd.maxRentDuration[i],
        cd.dailyRentPrice[i],
        _lendAmount,
        cd.paymentToken[i],
        cd.willAutoRenew[i]
      );

      lendingID++;
    }

    safeTransfer(
      cd,
      msg.sender,
      address(this),
      sliceArr(cd.tokenID, cd.left, cd.right, 0),
      sliceArr(cd.lendAmount, cd.left, cd.right, 0)
    );
  }

  function handleStopLend(IHadaro.CallData memory cd) private {
    uint256[] memory lentAmounts = new uint256[](cd.right - cd.left);
    for (uint256 i = cd.left; i < cd.right; i++) {
      bytes32 lendingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], cd.lendingID[i])
      );
      Lending storage lending = lendings[lendingIdentifier];
      ensureIsNotNull(lending);
      ensureIsStoppable(lending, msg.sender);
      require(
        cd.nftStandard[i] == lending.nftStandard,
        "Hadaro::invalid nft standard"
      );
      require(
        lending.lendAmount == lending.availableAmount,
        "Hadaro::actively rented"
      );
      lentAmounts[i - cd.left] = lending.lendAmount;
      emit IHadaro.StopLend(
        cd.lendingID[i],
        uint32(block.timestamp),
        lending.lendAmount
      );
      delete lendings[lendingIdentifier];
    }
    safeTransfer(
      cd,
      address(this),
      msg.sender,
      sliceArr(cd.tokenID, cd.left, cd.right, 0),
      sliceArr(lentAmounts, cd.left, cd.right, cd.left)
    );
  }

  function handleRent(IHadaro.CallData memory cd) private {
    for (uint256 i = cd.left; i < cd.right; i++) {
      bytes32 lendingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], cd.lendingID[i])
      );

      bytes32 rentingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], rentingID)
      );

      IHadaro.Lending storage lending = lendings[lendingIdentifier];
      IHadaro.Renting storage renting = rentings[rentingIdentifier];

      ensureIsNotNull(lending);
      ensureIsNull(renting);
      ensureIsRentable(lending, cd, i, msg.sender);

      require(
        cd.nftStandard[i] == lending.nftStandard,
        "Hadaro::invalid nft standard"
      );
      require(
        cd.rentAmount[i] <= lending.availableAmount,
        "Hadaro::invalid rent amount"
      );

      uint8 paymentTokenIx = uint8(lending.paymentToken);
      ERC20 paymentToken = ERC20(resolver.getPaymentToken(paymentTokenIx));
      uint256 decimals = paymentToken.decimals();

      {
        uint256 scale = 10 ** decimals;
        uint256 rentPrice = cd.rentAmount[i] *
          cd.rentDuration[i] *
          unpackPrice(lending.dailyRentPrice, scale);
        require(rentPrice > 0, "Hadaro::rent price is zero");

        paymentToken.safeTransferFrom(msg.sender, address(this), rentPrice);
      }

      rentings[rentingIdentifier] = IHadaro.Renting({
        renterAddress: payable(msg.sender),
        rentAmount: uint16(cd.rentAmount[i]),
        rentDuration: cd.rentDuration[i],
        rentedAt: uint32(block.timestamp)
      });

      lendings[lendingIdentifier].availableAmount -= uint16(cd.rentAmount[i]);

      emit IHadaro.Rent(
        msg.sender,
        cd.lendingID[i],
        rentingID,
        uint16(cd.rentAmount[i]),
        cd.rentDuration[i],
        renting.rentedAt
      );

      rentingID++;
    }
  }

  function handleStopRent(IHadaro.CallData memory cd) private {
    for (uint256 i = cd.left; i < cd.right; i++) {
      bytes32 lendingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], cd.lendingID[i])
      );
      bytes32 rentingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], cd.rentingID[i])
      );
      IHadaro.Lending storage lending = lendings[lendingIdentifier];
      IHadaro.Renting storage renting = rentings[rentingIdentifier];
      ensureIsNotNull(lending);
      ensureIsNotNull(renting);
      ensureIsReturnable(renting, msg.sender, block.timestamp);

      require(
        cd.nftStandard[i] == lending.nftStandard,
        "Hadaro::invalid nft standard"
      );
      require(
        renting.rentAmount <= lending.lendAmount,
        "Hadaro::critical error"
      );

      uint256 secondsSinceRentStart = block.timestamp - renting.rentedAt;

      distributePayments(lending, renting, secondsSinceRentStart);

      manageWillAutoRenew(
        lending,
        renting,
        cd.nftAddress[cd.left],
        cd.nftStandard[cd.left],
        cd.tokenID[i],
        cd.lendingID[i]
      );

      emit IHadaro.StopRent(cd.rentingID[i], uint32(block.timestamp));

      delete rentings[rentingIdentifier];
    }
  }

  function handleClaimRent(CallData memory cd) private {
    for (uint256 i = cd.left; i < cd.right; i++) {
      bytes32 lendingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], cd.lendingID[i])
      );
      bytes32 rentingIdentifier = keccak256(
        abi.encodePacked(cd.nftAddress[cd.left], cd.tokenID[i], cd.rentingID[i])
      );

      IHadaro.Lending storage lending = lendings[lendingIdentifier];
      IHadaro.Renting storage renting = rentings[rentingIdentifier];

      ensureIsNotNull(lending);
      ensureIsNotNull(renting);
      ensureIsClaimable(renting, block.timestamp);

      distributeClaimPayment(lending, renting);

      manageWillAutoRenew(
        lending,
        renting,
        cd.nftAddress[cd.left],
        cd.nftStandard[cd.left],
        cd.tokenID[i],
        cd.lendingID[i]
      );
      emit IHadaro.RentClaimed(cd.rentingID[i], uint32(block.timestamp));
      delete rentings[rentingIdentifier];
    }
  }

  //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
  // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

  function manageWillAutoRenew(
    IHadaro.Lending storage lending,
    IHadaro.Renting storage renting,
    address nftAddress,
    IHadaro.NFTStandard nftStandard,
    uint256 tokenID,
    uint256 _lendingID
  ) private {
    if (lending.willAutoRenew == false) {
      // No automatic renewal, stop the lending (or a portion of it) completely!

      // We must be careful here, because the lending might be for an ERC1155 token, which means
      // that the renting.rentAmount might not be the same as the lending.lendAmount. In this case, we
      // must NOT delete the lending, but only decrement the lending.lendAmount by the renting.rentAmount.
      // Notice: this is only possible for an ERC1155 tokens!
      if (lending.lendAmount > renting.rentAmount) {
        // update lending lendAmount to reflect NOT renewing the lending
        // Do not update lending.availableAmount, because the assets will not be lent out again
        lending.lendAmount -= renting.rentAmount;
        // return the assets to the lender
        IERC1155(nftAddress).safeTransferFrom(
          address(this),
          lending.lenderAddress,
          tokenID,
          uint256(renting.rentAmount),
          ""
        );
      }
      // If the lending is for an ERC721 token, then the renting.rentAmount is always the same as the
      // lending.lendAmount, and we can delete the lending. If the lending is for an ERC1155 token and
      // the renting.rentAmount is the same as the lending.lendAmount, then we can also delete the
      // lending.
      else if (lending.lendAmount == renting.rentAmount) {
        // return the assets to the lender
        if (nftStandard == IHadaro.NFTStandard.E721) {
          IERC721(nftAddress).transferFrom(
            address(this),
            lending.lenderAddress,
            tokenID
          );
        } else {
          IERC1155(nftAddress).safeTransferFrom(
            address(this),
            lending.lenderAddress,
            tokenID,
            uint256(renting.rentAmount),
            ""
          );
        }
        delete lendings[
          keccak256(abi.encodePacked(nftAddress, tokenID, _lendingID))
        ];
      }
      // StopLend event but only the amount that was not renewed (or all of it)
      emit IHadaro.StopLend(
        _lendingID,
        uint32(block.timestamp),
        renting.rentAmount
      );
    } else {
      // automatic renewal, make the assets available to be lent out again
      lending.availableAmount += renting.rentAmount;
    }
  }

  function bundleCall(
    function(IHadaro.CallData memory) handler,
    IHadaro.CallData memory cd
  ) private {
    require(cd.nftAddress.length > 0, "Hadaro::no nfts");
    while (cd.right != cd.nftAddress.length) {
      if (
        (cd.nftAddress[cd.left] == cd.nftAddress[cd.right]) &&
        (cd.nftStandard[cd.right] == IHadaro.NFTStandard.E1155)
      ) {
        cd.right++;
      } else {
        handler(cd);
        cd.left = cd.right;
        cd.right++;
      }
    }
    handler(cd);
  }

  function takeFee(uint256 rentAmt, ERC20 token) private returns (uint256 fee) {
    fee = rentAmt * rentFee;
    fee /= 10000;
    token.safeTransfer(beneficiary, fee);
  }

  function distributePayments(
    IHadaro.Lending memory lending,
    IHadaro.Renting memory renting,
    uint256 secondsSinceRentStart
  ) private {
    uint8 paymentTokenIx = uint8(lending.paymentToken);
    ERC20 paymentToken = ERC20(resolver.getPaymentToken(paymentTokenIx));
    uint256 decimals = paymentToken.decimals();
    uint256 scale = 10 ** decimals;
    uint256 rentPrice = renting.rentAmount *
      unpackPrice(lending.dailyRentPrice, scale);
    uint256 totalRenterPmt = rentPrice * renting.rentDuration;
    uint256 sendLenderAmt = (secondsSinceRentStart * rentPrice) /
      SECONDS_IN_DAY;

    require(totalRenterPmt > 0, "Hadaro::total renter payment is zero");
    require(sendLenderAmt > 0, "Hadaro::lender payment is zero");

    uint256 sendRenterAmt = totalRenterPmt - sendLenderAmt;

    if (rentFee != 0) {
      uint256 takenFee = takeFee(sendLenderAmt, paymentToken);
      sendLenderAmt -= takenFee;
    }

    paymentToken.safeTransfer(lending.lenderAddress, sendLenderAmt);
    if (sendRenterAmt > 0) {
      paymentToken.safeTransfer(renting.renterAddress, sendRenterAmt);
    }
  }

  function distributeClaimPayment(
    IHadaro.Lending memory lending,
    IHadaro.Renting memory renting
  ) private {
    uint8 paymentTokenIx = uint8(lending.paymentToken);
    ERC20 paymentToken = ERC20(resolver.getPaymentToken(paymentTokenIx));

    uint256 decimals = paymentToken.decimals();
    uint256 scale = 10 ** decimals;
    uint256 rentPrice = renting.rentAmount *
      unpackPrice(lending.dailyRentPrice, scale);
    uint256 finalAmt = rentPrice * renting.rentDuration;
    uint256 takenFee = 0;

    if (rentFee != 0) {
      takenFee = takeFee(finalAmt, paymentToken);
    }

    paymentToken.safeTransfer(lending.lenderAddress, finalAmt - takenFee);
  }

  function safeTransfer(
    CallData memory cd,
    address from,
    address to,
    uint256[] memory tokenID,
    uint256[] memory lendAmount
  ) private {
    if (cd.nftStandard[cd.left] == IHadaro.NFTStandard.E721) {
      IERC721(cd.nftAddress[cd.left]).transferFrom(
        from,
        to,
        cd.tokenID[cd.left]
      );
    } else {
      IERC1155(cd.nftAddress[cd.left]).safeBatchTransferFrom(
        from,
        to,
        tokenID,
        lendAmount,
        ""
      );
    }
  }

  //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
  // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

  function getLending(
    address nftAddress,
    uint256 tokenID,
    uint256 _lendingID
  )
    external
    view
    returns (uint8, address, uint8, bytes4, uint16, uint16, uint8)
  {
    bytes32 identifier = keccak256(
      abi.encodePacked(nftAddress, tokenID, _lendingID)
    );
    IHadaro.Lending storage lending = lendings[identifier];
    return (
      uint8(lending.nftStandard),
      lending.lenderAddress,
      lending.maxRentDuration,
      lending.dailyRentPrice,
      lending.lendAmount,
      lending.availableAmount,
      uint8(lending.paymentToken)
    );
  }

  function getRenting(
    address nftAddress,
    uint256 tokenID,
    uint256 _rentingID
  ) external view returns (address, uint16, uint8, uint32) {
    bytes32 identifier = keccak256(
      abi.encodePacked(nftAddress, tokenID, _rentingID)
    );
    IHadaro.Renting storage renting = rentings[identifier];
    return (
      renting.renterAddress,
      renting.rentAmount,
      renting.rentDuration,
      renting.rentedAt
    );
  }

  //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
  // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

  function createLendCallData(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendAmount,
    uint8[] memory maxRentDuration,
    bytes4[] memory dailyRentPrice,
    uint8[] memory paymentToken,
    bool[] memory willAutoRenew
  ) private pure returns (CallData memory cd) {
    cd = CallData({
      left: 0,
      right: 1,
      nftStandard: nftStandard,
      nftAddress: nftAddress,
      tokenID: tokenID,
      lendAmount: lendAmount,
      lendingID: new uint256[](0),
      rentingID: new uint256[](0),
      rentDuration: new uint8[](0),
      rentAmount: new uint256[](0),
      maxRentDuration: maxRentDuration,
      dailyRentPrice: dailyRentPrice,
      paymentToken: paymentToken,
      willAutoRenew: willAutoRenew
    });
  }

  function createRentCallData(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory _lendingID,
    uint8[] memory rentDuration,
    uint256[] memory rentAmount
  ) private pure returns (CallData memory cd) {
    cd = CallData({
      left: 0,
      right: 1,
      nftStandard: nftStandard,
      nftAddress: nftAddress,
      tokenID: tokenID,
      lendAmount: new uint256[](0),
      lendingID: _lendingID,
      rentingID: new uint256[](0),
      rentDuration: rentDuration,
      rentAmount: rentAmount,
      maxRentDuration: new uint8[](0),
      dailyRentPrice: new bytes4[](0),
      paymentToken: new uint8[](0),
      willAutoRenew: new bool[](0)
    });
  }

  function createActionCallData(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory _lendingID,
    uint256[] memory _rentingID
  ) private pure returns (CallData memory cd) {
    cd = CallData({
      left: 0,
      right: 1,
      nftStandard: nftStandard,
      nftAddress: nftAddress,
      tokenID: tokenID,
      lendAmount: new uint256[](0),
      lendingID: _lendingID,
      rentingID: _rentingID,
      rentDuration: new uint8[](0),
      rentAmount: new uint256[](0),
      maxRentDuration: new uint8[](0),
      dailyRentPrice: new bytes4[](0),
      paymentToken: new uint8[](0),
      willAutoRenew: new bool[](0)
    });
  }

  function unpackPrice(
    bytes4 price,
    uint256 scale
  ) private pure returns (uint256) {
    ensureIsUnpackablePrice(price, scale);
    uint16 whole = uint16(bytes2(price));
    uint16 decimal = uint16(bytes2(price << 16));
    uint256 decimalScale = scale / 10000;
    if (whole > 9999) {
      whole = 9999;
    }
    if (decimal > 9999) {
      decimal = 9999;
    }
    uint256 w = whole * scale;
    uint256 d = decimal * decimalScale;
    uint256 fullPrice = w + d;
    return fullPrice;
  }

  function sliceArr(
    uint256[] memory arr,
    uint256 fromIx,
    uint256 toIx,
    uint256 arrOffset
  ) private pure returns (uint256[] memory r) {
    r = new uint256[](toIx - fromIx);
    for (uint256 i = fromIx; i < toIx; i++) {
      r[i - fromIx] = arr[i - arrOffset];
    }
  }

  //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
  // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

  function ensureIsNotZeroAddr(address addr) private pure {
    require(addr != address(0), "Hadaro::zero address");
  }

  function ensureIsZeroAddr(address addr) private pure {
    require(addr == address(0), "Hadaro::not a zero address");
  }

  function ensureIsNull(Lending memory lending) private pure {
    ensureIsZeroAddr(lending.lenderAddress);
    require(lending.maxRentDuration == 0, "Hadaro::duration not zero");
    require(lending.dailyRentPrice == 0, "Hadaro::rent price not zero");
  }

  function ensureIsNotNull(Lending memory lending) private pure {
    ensureIsNotZeroAddr(lending.lenderAddress);
    require(lending.maxRentDuration != 0, "Hadaro::duration zero");
    require(lending.dailyRentPrice != 0, "Hadaro::rent price is zero");
  }

  function ensureIsNull(Renting memory renting) private pure {
    ensureIsZeroAddr(renting.renterAddress);
    require(renting.rentDuration == 0, "Hadaro::duration not zero");
    require(renting.rentedAt == 0, "Hadaro::rented at not zero");
  }

  function ensureIsNotNull(Renting memory renting) private pure {
    ensureIsNotZeroAddr(renting.renterAddress);
    require(renting.rentDuration != 0, "Hadaro::duration is zero");
    require(renting.rentedAt != 0, "Hadaro::rented at is zero");
  }

  function ensureIsLendable(CallData memory cd, uint256 i) private pure {
    require(cd.lendAmount[i] > 0, "Hadaro::lend amount is zero");
    require(cd.lendAmount[i] <= type(uint16).max, "Hadaro::not uint16");
    require(cd.maxRentDuration[i] > 0, "Hadaro::duration is zero");
    require(cd.maxRentDuration[i] <= type(uint8).max, "Hadaro::not uint8");
    require(uint32(cd.dailyRentPrice[i]) > 0, "Hadaro::rent price is zero");
  }

  function ensureIsRentable(
    Lending memory lending,
    CallData memory cd,
    uint256 i,
    address msgSender
  ) private pure {
    require(msgSender != lending.lenderAddress, "Hadaro::cant rent own nft");
    require(cd.rentDuration[i] <= type(uint8).max, "Hadaro::not uint8");
    require(cd.rentDuration[i] > 0, "Hadaro::duration is zero");
    require(cd.rentAmount[i] <= type(uint16).max, "Hadaro::not uint16");
    require(cd.rentAmount[i] > 0, "Hadaro::rentAmount is zero");
    require(
      cd.rentDuration[i] <= lending.maxRentDuration,
      "Hadaro::rent duration exceeds allowed max"
    );
  }

  function ensureIsReturnable(
    Renting memory renting,
    address msgSender,
    uint256 blockTimestamp
  ) private pure {
    require(renting.renterAddress == msgSender, "Hadaro::not renter");
    require(
      !isPastReturnDate(renting, blockTimestamp),
      "Hadaro::past return date"
    );
  }

  function ensureIsStoppable(
    Lending memory lending,
    address msgSender
  ) private pure {
    require(lending.lenderAddress == msgSender, "Hadaro::not lender");
  }

  function ensureIsUnpackablePrice(bytes4 price, uint256 scale) private pure {
    require(uint32(price) > 0, "Hadaro::invalid price");
    require(scale >= 10000, "Hadaro::invalid scale");
  }

  function ensureTokenNotSentinel(uint8 paymentIx) private pure {
    require(paymentIx > 0, "Hadaro::token is sentinel");
  }

  function ensureIsClaimable(
    IHadaro.Renting memory renting,
    uint256 blockTimestamp
  ) private pure {
    require(
      isPastReturnDate(renting, blockTimestamp),
      "Hadaro::return date not passed"
    );
  }

  function isPastReturnDate(
    Renting memory renting,
    uint256 nowTime
  ) private pure returns (bool) {
    require(nowTime > renting.rentedAt, "Hadaro::now before rented");
    return nowTime - renting.rentedAt > renting.rentDuration * SECONDS_IN_DAY;
  }

  //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
  // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

  function setRentFee(uint256 newRentFee) external onlyAdmin {
    require(newRentFee < 10000, "Hadaro::fee exceeds 100pct");
    rentFee = newRentFee;
  }

  function setAdmin(address newAdmin) external onlyAdmin {
    admin = newAdmin;
  }

  function setBeneficiary(address payable newBeneficiary) external onlyAdmin {
    beneficiary = newBeneficiary;
  }

  function setPaused(bool newPaused) external onlyAdmin {
    paused = newPaused;
  }

  function setResolver(address newResolver) external onlyAdmin {
    resolver = IResolver(newResolver);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./IResolver.sol";

interface IHadaro {
  event Lend(
    bool is721,
    address indexed lenderAddress,
    address indexed nftAddress,
    uint256 indexed tokenID,
    uint256 lendingID,
    uint8 maxRentDuration,
    bytes4 dailyRentPrice,
    uint16 lendAmount,
    uint8 paymentToken,
    bool willAutoRenew
  );

  event Rent(
    address indexed renterAddress,
    uint256 indexed lendingID,
    uint256 indexed rentingID,
    uint16 rentAmount,
    uint8 rentDuration,
    uint32 rentedAt
  );

  event StopLend(uint256 indexed lendingID, uint32 stoppedAt, uint16 amount);

  event StopRent(uint256 indexed rentingID, uint32 stoppedAt);

  event RentClaimed(uint256 indexed rentingID, uint32 collectedAt);

  enum NFTStandard {
    E721,
    E1155
  }

  struct CallData {
    uint256 left;
    uint256 right;
    IHadaro.NFTStandard[] nftStandard;
    address[] nftAddress;
    uint256[] tokenID;
    uint256[] lendAmount;
    uint8[] maxRentDuration;
    bytes4[] dailyRentPrice;
    uint256[] lendingID;
    uint256[] rentingID;
    uint8[] rentDuration;
    uint256[] rentAmount;
    uint8[] paymentToken;
    bool[] willAutoRenew;
  }

  // fits into a single storage slot
  // nftStandard       2
  // lenderAddress   162
  // maxRentDuration 170
  // dailyRentPrice  202
  // lendAmount      218
  // availableAmount 234
  // paymentToken    242
  // willAutoRenew   250
  // leaves a spare byte
  struct Lending {
    NFTStandard nftStandard;
    address payable lenderAddress;
    uint8 maxRentDuration;
    bytes4 dailyRentPrice;
    uint16 lendAmount;
    uint16 availableAmount;
    uint8 paymentToken;
    bool willAutoRenew;
  }

  // fits into a single storage slot
  // renterAddress 160
  // rentDuration  168
  // rentedAt      216
  // rentAmount    232
  // leaves 3 spare bytes
  struct Renting {
    address payable renterAddress;
    uint8 rentDuration;
    uint32 rentedAt;
    uint16 rentAmount;
  }

  // creates the lending structs and adds them to the enumerable set
  function lend(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendAmount,
    uint8[] memory maxRentDuration,
    bytes4[] memory dailyRentPrice,
    uint8[] memory paymentToken,
    bool[] memory willAutoRenew
  ) external;

  function stopLend(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendingID
  ) external;

  // creates the renting structs and adds them to the enumerable set
  function rent(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendingID,
    uint8[] memory rentDuration,
    uint256[] memory rentAmount
  ) external payable;

  function stopRent(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendingID,
    uint256[] memory rentingID
  ) external;

  function claimRent(
    IHadaro.NFTStandard[] memory nftStandard,
    address[] memory nftAddress,
    uint256[] memory tokenID,
    uint256[] memory lendingID,
    uint256[] memory rentingID
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IResolver {
  enum PaymentToken {
    SENTINEL,
    WETH,
    DAI,
    USDC,
    USDT,
    TUSD,
    HADARO
  }

  function getPaymentToken(uint8 _pt) external view returns (address);

  function setPaymentToken(uint8 _pt, address _v) external;
}