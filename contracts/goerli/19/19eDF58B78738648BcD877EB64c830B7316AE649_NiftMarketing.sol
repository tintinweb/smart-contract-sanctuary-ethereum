// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NiftMarketing is ERC721Holder, ERC1155Receiver, ERC1155Holder, ReentrancyGuard {
    
    //add in External file
    event CreatMarketing(
        address indexed collectionAddress,
        uint256[] indexed tokenIds,
        uint8 typeId,
        uint8[] optionIds,
        bool isExclusive,
        uint256 dailyPrice,
        uint256 penaltyValue,
        uint256 depositValue,
        uint32 startDate,
        uint32 endDate,
        bool isCollection,
        address indexed sellerAddress,
        uint256 marketingId,
        uint32 createdTime
    );
    event AddItemInMarketing( uint256 indexed marketingId, address indexed collectionAddress, uint256[] indexed tokenIds, uint32 updatedTime );
    event ChangeMarketingStatus(uint256 indexed marketingId, bool status, uint32 openedTime);    
    event PurchaseMarketing( uint256 indexed marketingId, uint256 indexed purchaseId, address indexed buyerAddress, uint8 duration, uint32 purchasedTime );
    event UpdatePeriodOfMarketing( uint256 indexed marketingId, uint32 startDate, uint32 endDate, uint32 updatedTime );
    event UpdateDurationOfPurchase( uint256 indexed marketingId, uint256 indexed purchaseId, uint8 duration, uint32 updatedTime );
    event BurnMarketingItems( uint256 indexed marketingId, address indexed collectionAddress, uint256[] indexed tokenIds, uint32 updatedTime );
    event WithdrawMarketingAmount( uint256 indexed marketingId, address indexed tokenOwnerAddress, uint256 amount, uint32 claimedTime );
    event WithdrawCollateral( uint256 indexed marketingId, uint256 indexed purchaseId, uint256 amount, uint32 claimedTime);

    address private admin;
    uint256 private marketingId = 1;
    uint256 public votingDays = 7;

    uint8 public marketingTypeNumber = 1;
    uint8 public marketingOptionNumber = 1;
    mapping(uint8 => string) public marketingTypes;
    mapping(uint8 => string) public marketingOptions;

    // uint256 public marketingFee = 0;
    
    struct Proposal {
        uint256 offerPrice;
        address delegate;
        uint voteCount;
        uint16 positiveVote;
        uint16 nagetiveVote;
        uint256 endtime;
        bool isComplate;
    }
    
    struct VotingList {
        bool voted;
        address delegate;
    }

    struct ProposalHistory {
        uint256 marketingId;
        uint256 offerPrice;
        address delegate;
        uint voteCount;
        uint16 positiveVote;
        uint16 nagetiveVote;
        bool status;
        uint256 endtime;
    }

    struct Marketing {
        address payable creator;
        address collection;
        uint8 typeId;
        uint8[] optionIds;
        bool isExclusive;
        uint256 dailyPrice;
        uint256 penaltyValue;
        uint256 depositValue;
        uint32 startDate;
        uint32 endDate;
        bool isCollection;
        bool isActive;
        uint32 currentPurchaseId;
        uint256[] tokenIds;
        uint256 balance;
        Proposal proposal;
    }

    struct TokenOwner {
        uint256 tokenCount;
        uint256 withdrewAmount;
    }
    mapping(uint256 => ProposalHistory[]) public proposalHistory;
    mapping(uint256 => Marketing) marketings;
    mapping(uint256 => mapping(uint256=>mapping(address => VotingList))) public collectionVotingList;
    mapping(uint256 => mapping(address => TokenOwner)) marketingOwnerBalance;
    mapping(uint256 => mapping(uint256 => address)) public marketingTokenIdOwner;
    mapping(uint256 => mapping(uint256 => uint256)) public marketingTokenIdIndex;

    struct Purchase {
        address payable creator;
        uint8 duration;
        uint256 collateral;
        uint32 purchasedTime;
        uint32 endTime;
    }

    mapping(uint256 => mapping(uint256 => Purchase)) marketingPurchases;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Niftopia:: Only admin's");
        _;
    }

    modifier onlyMarketingCreator(uint256 _marketingId) {
        require(_marketingId < marketingId, "Contract ID does not exist");
        require(
            msg.sender == marketings[_marketingId].creator,
            "You must be the creator of this contract"
        );
        _;
    }

    modifier onlyPurchaseCreator(uint256 _marketingId, uint256 _purchaseId) {
        require(_marketingId < marketingId, "Contract ID does not exist");
        require(
            _purchaseId > 0 &&
                _purchaseId <= marketings[_marketingId].currentPurchaseId,
            "purchase ID error"
        );
        require(
            msg.sender == marketingPurchases[_marketingId][_purchaseId].creator,
            "You must be the creator of this purchase"
        );
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setMarketingTypes(string memory marketingType) external onlyAdmin {
        require( keccak256(abi.encodePacked(marketingType)) != keccak256(abi.encodePacked("")), "" );
        
        bool isAdded = false;
        for (uint8 i = 0; i < marketingTypeNumber; i++) {
            if(keccak256(abi.encodePacked(marketingTypes[i])) == keccak256(abi.encodePacked(marketingType))){
                isAdded = true;
            }
        }

        if(!isAdded){
            marketingTypes[marketingTypeNumber] = marketingType;
            marketingTypeNumber++;
        }
    }

    function setMarketingOptions(string memory marketingOption)
        external
        onlyAdmin
    {
        require( keccak256(abi.encodePacked(marketingOption)) != keccak256(abi.encodePacked("")), "" );
        bool isAdded = false;
        for (uint8 i = 0; i < marketingOptionNumber; i++) {
            if(keccak256(abi.encodePacked(marketingOptions[i])) == keccak256(abi.encodePacked(marketingOption))){
                isAdded = true;
            }
        }
        if(!isAdded){
            marketingOptions[marketingOptionNumber] = marketingOption;
            marketingOptionNumber++;
        }
    }

    // Create Marketing for new Collection
    function createMarketing(Marketing memory _marketing) external {
        ensureIsNotZeroAddr(_marketing.collection);
        require(_marketing.dailyPrice >= 0.00001 ether, "");
        require(_marketing.typeId > 0 && _marketing.typeId < marketingTypeNumber, "");
        require(_marketing.startDate > uint32(block.timestamp), "Start date error");
        require(_marketing.endDate > _marketing.startDate, "End date error");
        
        for (uint32 i = 0; i < _marketing.optionIds.length; i++) {
            require(
                _marketing.optionIds[i] > 0 && _marketing.optionIds[i] < marketingOptionNumber,
                "Niftopia::Marketing options are incorrect"
            );
        }
        _marketing.creator = payable(msg.sender);
        _marketing.isActive = true;
        _marketing.currentPurchaseId = 0;
        _marketing.balance = 0;

        if(_marketing.isCollection){
            _marketing.proposal = Proposal({
                offerPrice: 0,
                delegate: address(0),
                voteCount: 0,
                positiveVote:0,
                nagetiveVote:0,
                endtime:block.timestamp,
                isComplate: true
            });
        }

        uint256[] memory tokenIds = _marketing.tokenIds; 

        _marketing.tokenIds = new uint256[](0);

        // Add Marketing data in Mapping
        marketings[marketingId] = _marketing;

        // check if ERC721 Token or not
        require( is721(_marketing.collection),  "Niftopia::Collection must be ERC721 token.");

        if (!_marketing.isCollection) {
            require(tokenIds.length > 0, "token ID is required");
            _addItemInMarketing(marketingId, _marketing.collection, tokenIds);
        }
        marketingId++;
        emit CreatMarketing( _marketing.collection, tokenIds, _marketing.typeId, _marketing.optionIds, _marketing.isExclusive, _marketing.dailyPrice, _marketing.penaltyValue, _marketing.depositValue, _marketing.startDate, _marketing.endDate, _marketing.isCollection, msg.sender, marketingId, uint32(block.timestamp));
    }

    //Update marketing time Period
    function updatePeriodOfMarketing(
        uint256 _marketingId,
        uint32 _startDate,
        uint32 _endDate
    ) external onlyMarketingCreator(_marketingId) {
        require(_startDate > uint32(block.timestamp), "Start date error");
        require(_endDate > _startDate, "End date error");
        Marketing storage marketing = marketings[_marketingId];
        marketing.startDate = _startDate;
        marketing.endDate = _endDate;

        emit UpdatePeriodOfMarketing( _marketingId, _startDate, _endDate, uint32(block.timestamp) );
    }

     // Extra Items add in Marketing Collections
    function addItemInMarketingCollection(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) external {
        ensureIsMarketingAssets(_marketingId, _collectionAddress, _tokenIds);
        Marketing memory marketing = marketings[_marketingId];

        require( marketing.currentPurchaseId == 0, "You can't add items because contract is live." );

        _addItemInMarketing(marketingId, _collectionAddress, _tokenIds);

        emit AddItemInMarketing( _marketingId, _collectionAddress, _tokenIds, uint32(block.timestamp) );
    }

    function _addItemInMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) private {
        uint256 tokenCount = marketings[_marketingId].tokenIds.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            marketings[_marketingId].tokenIds.push(_tokenIds[i]);
            tokenCount++;
            
            marketingOwnerBalance[_marketingId][msg.sender].tokenCount++;
            marketingTokenIdOwner[_marketingId][_tokenIds[i]] = msg.sender;
            marketingTokenIdIndex[_marketingId][_tokenIds[i]] = tokenCount;
            if (is721(_collectionAddress)) {
                IERC721(_collectionAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _tokenIds[i],
                    ""
                );
            }
        }
    }

    //from Item from Marketing collection
    function burnMarketingItem(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) external {
        ensureIsMarketingAssets(_marketingId, _collectionAddress, _tokenIds);
        require( marketings[_marketingId].currentPurchaseId == 0, "You can't withdraw items" );

        _burnMarketingItem(_marketingId, _collectionAddress, _tokenIds);
        emit BurnMarketingItems( _marketingId, _collectionAddress, _tokenIds, uint32(block.timestamp));
    }

    function _burnMarketingItem(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) private {
        uint256 tokenIndex;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require( marketingTokenIdOwner[_marketingId][_tokenIds[i]] == msg.sender, "You are not the owner of the token" );
            tokenIndex = marketingTokenIdIndex[_marketingId][_tokenIds[i]];
            delete marketings[_marketingId].tokenIds[tokenIndex];
            if (marketingOwnerBalance[marketingId][msg.sender].tokenCount > 0) {
                marketingOwnerBalance[marketingId][msg.sender].tokenCount--;
            }
            marketingTokenIdOwner[marketingId][_tokenIds[i]] = address(0x0);
            marketingTokenIdIndex[marketingId][_tokenIds[i]] = 0;
            if (is721(_collectionAddress)) {
                IERC721(_collectionAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _tokenIds[i],
                    ""
                );
            }
        }
    }

    //Change Marketing Status
    function changeMarketingStatus(uint256 _marketingId) external onlyMarketingCreator(_marketingId) {
        Marketing storage marketing = marketings[_marketingId];
        marketing.isActive = !marketing.isActive;
        emit ChangeMarketingStatus(_marketingId, marketing.isActive, uint32(block.timestamp));
    }

    function purchaseMarketing(uint256 _marketingId, uint8 _duration) external payable {

        require(_marketingId > 0 && _marketingId < marketingId, "Contract ID does not exist");
        require(_duration > 0, "Duration should be more than 0");
        
        Marketing storage marketing = marketings[_marketingId];
        
        require(marketing.isActive, "This contract is disabled");
        if (marketing.isExclusive) {
            require( marketing.currentPurchaseId == 0, "This contract is exclusive and has already been bought." );
        }
        
        //check end date and duration compaire
        uint32 endTime = uint32(block.timestamp);
        if (endTime < marketing.startDate) {
            endTime = marketing.startDate + (_duration * 1 days);
        } else {
            endTime = endTime + (_duration * 1 days);
        }
        require(endTime <= marketing.endDate, "Date out of range");
         
        uint256 dailyPriceVal = marketing.dailyPrice;
        uint256 _collateral = marketing.depositValue;
        uint32 purchasedTime = uint32(block.timestamp);

        if(marketing.isCollection){
            require(marketing.proposal.delegate == msg.sender, "Invalid proposal user");
            require(marketing.proposal.endtime < block.timestamp, "Voting result has not finalized");
            require(marketing.proposal.positiveVote > marketing.proposal.nagetiveVote, "Propsal does not have enough votes");
            dailyPriceVal = marketing.proposal.offerPrice;
        }

        require( msg.value >= ((dailyPriceVal * _duration) + marketing.depositValue), "You have to deposit enough money" );

        Purchase memory purchase = Purchase({
            creator: payable(msg.sender),
            duration: _duration,
            collateral: _collateral,
            purchasedTime: purchasedTime, 
            endTime: endTime
        });
        marketing.currentPurchaseId++;

        marketingPurchases[_marketingId][marketing.currentPurchaseId] = purchase;
        marketing.balance = marketing.balance + ((dailyPriceVal * _duration) * 95) / 100;
        
        if (is721(marketing.collection)) {
                IERC721(marketing.collection).safeTransferFrom(
                    msg.sender,
                    address(this),
                    ((dailyPriceVal * _duration) * 5) / 100,
                    ""
                );
            }

        if(marketing.isCollection){
            proposalHistory[_marketingId].push(ProposalHistory(
                _marketingId,
                marketing.proposal.offerPrice,
                marketing.proposal.delegate,
                marketing.proposal.voteCount,
                marketing.proposal.positiveVote,
                marketing.proposal.nagetiveVote,
                true, 
                marketing.proposal.endtime
            ));

            marketings[_marketingId].proposal = Proposal({
                offerPrice: 0,
                delegate: address(0),
                voteCount: 0,
                positiveVote:0,
                nagetiveVote:0,
                endtime:block.timestamp,
                isComplate: true
            });
        }

        emit PurchaseMarketing( _marketingId, marketing.currentPurchaseId, msg.sender, _duration, purchasedTime );
    }

    function vote(uint256 _marketingId, uint256 _proposalId, bool _vote) public {
        require(_marketingId > 0 && _marketingId < marketingId, "Contract ID does not exist");
        
        Marketing storage marketing = marketings[_marketingId];
        ProposalHistory storage proposal = proposalHistory[_marketingId][_proposalId];

        uint256 balanceOfd = IERC721(marketing.collection).balanceOf(msg.sender);

        require(balanceOfd > 0, "Not a delegated member");
        require(marketing.proposal.endtime > block.timestamp, "Voting has not finalized");
        require(proposal.delegate != msg.sender, "Can't vote for yourself");
        
        if(collectionVotingList[_marketingId][_proposalId][msg.sender].delegate == proposal.delegate){ 
            if(collectionVotingList[_marketingId][_proposalId][msg.sender].voted){
                proposalHistory[_marketingId][_proposalId].positiveVote --;
            }else{
                proposalHistory[_marketingId][_proposalId].nagetiveVote --;
            }
            proposalHistory[_marketingId][_proposalId].voteCount --;
        }
        
        if(_vote){
            proposalHistory[_marketingId][_proposalId].positiveVote++; 
        }else{
            proposalHistory[_marketingId][_proposalId].nagetiveVote++;
        }

        proposalHistory[_marketingId][_proposalId].voteCount++;
        
        if(marketing.proposal.delegate == proposal.delegate)
        {
            marketing.proposal.positiveVote = proposalHistory[_marketingId][_proposalId].positiveVote;
            marketing.proposal.nagetiveVote = proposalHistory[_marketingId][_proposalId].nagetiveVote;
            marketing.proposal.voteCount = proposalHistory[_marketingId][_proposalId].voteCount;
        }

        collectionVotingList[_marketingId][_proposalId][msg.sender] = VotingList({ voted:_vote,delegate:proposal.delegate});

    }

    function placeProposal(uint256 _offerPrice , uint256 _marketingId) public {
        require(_marketingId > 0 && _marketingId < marketingId, "Contract ID does not exist");
        Marketing storage marketing = marketings[_marketingId];

        require(marketing.isCollection, "Not a collection");
        require(marketing.isActive, "This contract is disabled");
        if (marketing.isExclusive) {
            require(marketing.currentPurchaseId == 0, "this contract is exclusive and has already been bought." );        
        }
        // require(_offerPrice >= marketing.offerPrice, "price wan't less then current price");

        if(!marketing.proposal.isComplate){ 
            if(marketing.proposal.endtime < block.timestamp){
                if(marketing.proposal.positiveVote <= marketing.proposal.nagetiveVote){
                    proposalHistory[_marketingId].push(ProposalHistory({
                        marketingId:_marketingId,
                        offerPrice: marketing.proposal.offerPrice,
                        delegate: marketing.proposal.delegate,
                        voteCount: marketing.proposal.voteCount,
                        positiveVote:marketing.proposal.positiveVote,
                        nagetiveVote:marketing.proposal.nagetiveVote,
                        endtime:marketing.proposal.endtime,
                        status: false
                    }));
                }
            }
        }else{
            require(marketing.proposal.delegate == address(0), "Other proposal is currently running");
        }

        // uint256 expiration = block.timestamp * (votingDays * 1 days);

        uint256 expiration = block.timestamp+300;

        marketings[_marketingId].proposal = Proposal({
            offerPrice: _offerPrice,
            delegate: msg.sender,
            voteCount: 0,
            positiveVote:0,
            nagetiveVote:0,
            endtime: expiration,
            isComplate: false
        });

    }

    function upgradeDurationOfPurchase( uint256 _marketingId, uint256 _purchaseId, uint8 _duration ) external payable onlyPurchaseCreator(_marketingId, _purchaseId) {
        Marketing storage marketing = marketings[_marketingId];
        Purchase storage purchase = marketingPurchases[_marketingId][_purchaseId];
        require(_duration > purchase.duration, "Duration should be higher than purchase duration");
        require( msg.value == marketing.dailyPrice * (_duration - purchase.duration), "You have to deposit enough money");

        uint32 endTime = uint32(block.timestamp);
        if (endTime < marketing.startDate) {
            endTime = marketing.startDate + 86400 * _duration;
        } else {
            endTime = endTime + 86400 * _duration;
        }

        uint256 amount = msg.value;
        require(endTime <= marketing.endDate, "Date out of range");
        purchase.duration = _duration;
        purchase.endTime = endTime;
        marketing.balance += amount;

        emit UpdateDurationOfPurchase( _marketingId, _purchaseId, _duration, uint32(block.timestamp));
    }

    function burnMarketing(uint256 _marketingId) external onlyMarketingCreator(_marketingId) {
        require( _marketingId > 0 && _marketingId < marketingId, "Contract out of range" );

        Marketing memory marketing = marketings[_marketingId];
        
        require(marketing.currentPurchaseId == 0, "Purchased contract");

        marketings[_marketingId].isActive = false;
        
        if (!marketing.isCollection) {
            
            for (uint256 i = 0; i < marketing.tokenIds.length; i++) {
                
                IERC721(marketing.collection).safeTransferFrom(
                    address(this),
                    msg.sender,
                    marketing.tokenIds[i],
                    ""
                );

                if (marketingOwnerBalance[_marketingId][msg.sender].tokenCount > 0 ) {
                    marketingOwnerBalance[_marketingId][msg.sender].tokenCount--;
                }
                marketingTokenIdOwner[_marketingId][marketing.tokenIds[i]] = address(0x0);
                marketingTokenIdIndex[_marketingId][marketing.tokenIds[i]] = 0;
                delete marketings[_marketingId].tokenIds[i];
            }

        }

        emit ChangeMarketingStatus(_marketingId, false, uint32(block.timestamp));
    }

    //Withdraw deposite value
    function withdrawCollateral(uint256 _marketingId, uint256 _purchaseId) external onlyPurchaseCreator(_marketingId, _purchaseId) nonReentrant {
        require(_marketingId > 0 && _marketingId < marketingId, "Contract ID does not exist");
        Marketing storage marketing = marketings[_marketingId];

        require(marketingPurchases[_marketingId][_purchaseId].endTime < block.timestamp, "Purchased contract");

        if (marketing.isExclusive) {
            marketings[_marketingId].currentPurchaseId = 0;
        }
        uint256 collateralAMount = marketingPurchases[_marketingId][_purchaseId].collateral;
        marketingPurchases[_marketingId][_purchaseId].collateral = 0;

        // bool isSent = payable(msg.sender).send(collateralAMount);
        // require(isSent, "Failed to send Ether");
        
        (bool isSent, ) = payable(msg.sender).call{value: collateralAMount}("");
        require(isSent, "Failed to send crypto token");


        emit WithdrawCollateral(_marketingId, _purchaseId, collateralAMount, uint32(block.timestamp));
    }

    //Withdraw marketing fees
    function withdrawMarketingAmount(uint256 _marketingId) external nonReentrant{
        require(_marketingId > 0 && _marketingId < marketingId, "Contract out of range");

        Marketing memory marketing = marketings[_marketingId];
        require(marketing.currentPurchaseId == 0, "Purchased contract");

        TokenOwner storage tokenOwner = marketingOwnerBalance[_marketingId][
            msg.sender
        ];
        uint256 withdrawableFees = _withdrawableMarketingFees( marketing, tokenOwner );
        // bool isSent = payable(msg.sender).send(withdrawableFees);
        // require(isSent, "Failed to send Ether");

        (bool isSent, ) = payable(msg.sender).call{value: withdrawableFees}("");
        require(isSent, "Failed to send crypto token");

        tokenOwner.withdrewAmount += withdrawableFees;
        emit WithdrawMarketingAmount( _marketingId, msg.sender, withdrawableFees, uint32(block.timestamp));
    }

    // count Marketing withdrable fees
    function calculateMarketingFees(uint256 _marketingId, address _ownerAddr) external view returns (uint256) {
        require( _marketingId > 0 && _marketingId < marketingId, "Contract out of range" );
        Marketing memory marketing = marketings[_marketingId];
        require(marketing.creator == _ownerAddr, "You are not the contract creator" );
        TokenOwner memory tokenOwner = marketingOwnerBalance[_marketingId][_ownerAddr];
        return _withdrawableMarketingFees(marketing, tokenOwner);
    }

    // Return Marketing Amount fees
    function _withdrawableMarketingFees( Marketing memory marketing, TokenOwner memory tokenOwner) private pure returns (uint256) {
        uint256 userFees = marketing.balance;
        if(!marketing.isCollection){
            userFees = (userFees * tokenOwner.tokenCount) / marketing.tokenIds.length;
        }
        return userFees - tokenOwner.withdrewAmount;
    }

    // get purchase Marketing items
    function getTokenOwnerData(address _tokenOwnerAddress, uint256 _marketingId) external view returns (TokenOwner memory){
        require( _marketingId != 0 && _marketingId < marketingId, "Contract ID does not exist" );
        require( marketingOwnerBalance[_marketingId][_tokenOwnerAddress].tokenCount > 0, "Something's wrong with the address");
        return marketingOwnerBalance[_marketingId][_tokenOwnerAddress];
    }

    function getLastMarketingId() external view returns (uint256) {
        return marketingId - 1;
    }

    function getMarketingDetail(uint256 _marketingId) external view returns (Marketing memory) {
        require( _marketingId != 0 && _marketingId < marketingId, "Marketing ID does not exist" );
        Marketing memory marketing = marketings[_marketingId];

        if(!marketing.proposal.isComplate){
            if(marketing.proposal.endtime < block.timestamp){
                marketing.proposal.isComplate = true;
            }
        }
        
        return marketing; 
    }

    function getTimeDiffence(uint256 _marketingId) external view returns (bool) {
        Marketing memory marketing = marketings[_marketingId];
        return (marketing.proposal.endtime < block.timestamp);
    }

    function getMarketingPurchaseDetail( uint256 _marketingId, uint256 _purchaseId) external view returns (Purchase memory) {
        require( _marketingId != 0 && _marketingId < marketingId, "Contract ID does not exist");
        require( _purchaseId > 0 && _purchaseId <= marketings[_marketingId].currentPurchaseId, "Purchase ID error" );
        Purchase memory purchase = marketingPurchases[_marketingId][_purchaseId];
        return purchase;
    }

    function ensureIsMarketingAssets(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) private view {
        require(_marketingId > 0 && _marketingId < marketingId, "Contract ID does not exist");
        require(marketings[_marketingId].isCollection, "Can't add items in own contract" );
        ensureIsNotZeroAddr(_collectionAddress);
        require( _collectionAddress == marketings[_marketingId].collection, "Collection address must be same as the contract collection address." );
        require(_tokenIds.length > 0, "Please add token ID's");
    }

    function is721(address _nft) private view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC721).interfaceId);
    }

    function is1155(address _nft) private view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC1155).interfaceId);
    }

    function ensureIsNotZeroAddr(address _addr) private pure {
        require(_addr != address(0), "Niftopia::null address");
    }

    function ensureIsZeroAddr(address _addr) private pure {
        require(_addr == address(0), "Niftopia::Not an address");
    }

    function getTotalBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }
}