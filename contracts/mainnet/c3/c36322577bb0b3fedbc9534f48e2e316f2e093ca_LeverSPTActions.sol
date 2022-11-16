// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {sub, wmul, wdiv} from "fiat/utils/Math.sol";

interface IConvergentCurvePool {
    function solveTradeInvariant(
        uint256 amountX,
        uint256 reserveX,
        uint256 reserveY,
        bool out
    ) external view returns (uint256);

    function percentFee() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
}

/// @notice Helper methods for Element Finance's CurveConvergentPool
/// Link: https://github.com/element-fi/elf-contracts/blob/main/contracts/ConvergentCurvePool.sol
library ConvergentCurvePoolHelper {
    error ConvergentCurvePoolHelper__swapPreview_tokenMismatch();

    /// @notice Preview method for `onSwap()`
    /// @param balancerVault Address of the Balancer Vault contract
    /// @param poolId Id of the Balancer pool
    /// @param amountIn_ Input amount of swap [wad]
    function swapPreview(
        address balancerVault,
        bytes32 poolId,
        uint256 amountIn_,
        bool fromUnderlying,
        address bond,
        address underlying,
        uint256 bondScale,
        uint256 underlyingScale
    ) internal view returns (uint256) {
        // amountIn needs to be converted to wad
        uint256 amountIn = (fromUnderlying) ? wdiv(amountIn_, underlyingScale) : wdiv(amountIn_, bondScale);

        // determine the current pool balances and convert them to wad
        uint256 currentBalanceTokenIn;
        uint256 currentBalanceTokenOut;
        {
            (address[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(
                poolId
            );

            if (tokens[0] == underlying && tokens[1] == bond) {
                currentBalanceTokenIn = (fromUnderlying)
                    ? wdiv(balances[0], underlyingScale)
                    : wdiv(balances[1], bondScale);
                currentBalanceTokenOut = (fromUnderlying)
                    ? wdiv(balances[1], bondScale)
                    : wdiv(balances[0], underlyingScale);
            } else if (tokens[0] == bond && tokens[1] == underlying) {
                currentBalanceTokenIn = (fromUnderlying)
                    ? wdiv(balances[1], underlyingScale)
                    : wdiv(balances[0], bondScale);
                currentBalanceTokenOut = (fromUnderlying)
                    ? wdiv(balances[0], bondScale)
                    : wdiv(balances[1], underlyingScale);
            } else {
                revert ConvergentCurvePoolHelper__swapPreview_tokenMismatch();
            }
        }

        (address pool, ) = IBalancerVault(balancerVault).getPool(poolId);
        IConvergentCurvePool ccp = IConvergentCurvePool(pool);

        // adapted from `_adjustedReserve()`
        // adjust the bond reserve and leaves the underlying reserve as is
        if (fromUnderlying) {
            unchecked {
                currentBalanceTokenOut += ccp.totalSupply();
            }
        } else {
            unchecked {
                currentBalanceTokenIn += ccp.totalSupply();
            }
        }

        // perform the actual trade calculation
        uint256 amountOut = ccp.solveTradeInvariant(amountIn, currentBalanceTokenIn, currentBalanceTokenOut, true);

        // adapted from `_assignTradeFee()`
        // only the `isInputTrade` == false logic applies since this method only takes `amountIn`
        // If the output is the bond the implied yield is out - in
        // If the output is underlying the implied yield is in - out
        uint256 impliedYieldFee = wmul(
            ccp.percentFee(),
            fromUnderlying ? sub(amountOut, amountIn) : sub(amountIn, amountOut)
        );
        // subtract the impliedYieldFee from amountOut and convert it from wad to either bondScale or underlyingScale
        return wmul(sub(amountOut, impliedYieldFee), (fromUnderlying) ? bondScale : underlyingScale);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {WAD, toInt256, mul, div, wmul, wdiv} from "fiat/utils/Math.sol";

import {LeverActions} from "./LeverActions.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Lever20Actions
/// @notice A set of vault actions for modifying positions collateralized by ERC20 tokens
contract Lever20Actions is LeverActions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error Lever20Actions__enterVault_zeroVaultAddress();
    error Lever20Actions__enterVault_zeroTokenAddress();
    error Lever20Actions__exitVault_zeroVaultAddress();
    error Lever20Actions__exitVault_zeroTokenAddress();
    error Lever20Actions__exitVault_zeroToAddress();

    constructor(
        address codex,
        address fiat,
        address flash,
        address moneta,
        address publican,
        bytes32 fiatPoolId,
        address fiatBalancerVault
    ) LeverActions(codex, fiat, flash, moneta, publican, fiatPoolId, fiatBalancerVault) {}

    /// @notice Deposits amount of `token` with `tokenId` from `from` into the `vault`
    /// @dev Implements virtual method defined in Lever20Actions for ERC20 tokens
    /// @param vault Address of the Vault to enter
    /// @param token Address of the collateral token
    /// @param *tokenId ERC1155 TokenId (leave empty for ERC20 tokens)
    /// @param from Address from which to take the deposit from
    /// @param amount Amount of collateral tokens to deposit [tokenScale]
    function enterVault(
        address vault,
        address token,
        uint256, /* tokenId */
        address from,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert Lever20Actions__enterVault_zeroVaultAddress();
        if (token == address(0)) revert Lever20Actions__enterVault_zeroTokenAddress();

        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }

        IERC20(token).approve(vault, amount);
        IVault(vault).enter(0, address(this), amount);
    }

    /// @notice Withdraws amount of `token` with `tokenId` to `to` from the `vault`
    /// @dev Implements virtual method defined in Lever20Actions for ERC20 tokens
    /// @param vault Address of the Vault to exit
    /// @param token Address of the collateral token
    /// @param *tokenId ERC1155 TokenId (leave empty for ERC20 tokens)
    /// @param to Address which receives the withdrawn collateral tokens
    /// @param amount Amount of collateral tokens to exit [tokenScale]
    function exitVault(
        address vault,
        address token,
        uint256, /* tokenId */
        address to,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert Lever20Actions__exitVault_zeroVaultAddress();
        if (token == address(0)) revert Lever20Actions__exitVault_zeroTokenAddress();
        if (to == address(0)) revert Lever20Actions__exitVault_zeroToAddress();

        IVault(vault).exit(0, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {IFlash, ICreditFlashBorrower, IERC3156FlashBorrower} from "fiat/interfaces/IFlash.sol";
import {IPublican} from "fiat/interfaces/IPublican.sol";
import {WAD, toInt256, add, wmul, wdiv, sub} from "fiat/utils/Math.sol";

import {IBalancerVault} from "../helper/ConvergentCurvePoolHelper.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title LeverActions
/// @notice
abstract contract LeverActions {
    /// ======== Custom Errors ======== ///

    error LeverActions__exitMoneta_zeroUserAddress();

    /// ======== Storage ======== ///

    struct FlashLoanData {
        // Action to perform in the flash loan callback [1 - buy, 2 - sell, 3 - redeem]
        uint256 action;
        // Data corresponding to the action
        bytes data;
    }

    struct SellFIATSwapParams {
        // Paired asset with FIAT (e.g. DAI, USDC)
        address assetOut;
        // Min. amount of tokens we would accept to receive from the swap
        uint256 minAmountOut;
        // Timestamp at which swap must be confirmed by [seconds]
        uint256 deadline;
    }

    struct BuyFIATSwapParams {
        // Paired asset with FIAT (e.g. DAI, USDC)
        address assetIn;
        // Max. amount of tokens to be swapped for exactAmountOut of FIAT
        uint256 maxAmountIn;
        // Timestamp at which swap must be confirmed by [seconds]
        uint256 deadline;
    }

    /// @notice Codex
    ICodex public immutable codex;
    /// @notice FIAT token
    IFIAT public immutable fiat;
    /// @notice Flash
    IFlash public immutable flash;
    /// @notice Moneta
    IMoneta public immutable moneta;
    /// @notice Publican
    IPublican public immutable publican;

    address internal immutable self = address(this);

    // FIAT - DAI - USDC Balancer Pool
    bytes32 public immutable fiatPoolId;
    address public immutable fiatBalancerVault;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes32 public constant CALLBACK_SUCCESS_CREDIT = keccak256("CreditFlashBorrower.onCreditFlashLoan");

    constructor(
        address codex_,
        address fiat_,
        address flash_,
        address moneta_,
        address publican_,
        bytes32 fiatPoolId_,
        address fiatBalancerVault_
    ) {
        codex = ICodex(codex_);
        fiat = IFIAT(fiat_);
        flash = IFlash(flash_);
        moneta = IMoneta(moneta_);
        publican = IPublican(publican_);
        fiatPoolId = fiatPoolId_;
        fiatBalancerVault = fiatBalancerVault_;

        (address[] memory tokens, , ) = IBalancerVault(fiatBalancerVault_).getPoolTokens(fiatPoolId);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(fiatBalancerVault_, type(uint256).max);
        }

        fiat.approve(moneta_, type(uint256).max);
    }

    /// @notice Sets `amount` as the allowance of `spender` over the UserProxy's FIAT
    /// @param spender Address of the spender
    /// @param amount Amount of tokens to approve [wad]
    function approveFIAT(address spender, uint256 amount) external {
        fiat.approve(spender, amount);
    }

    /// @dev Redeems FIAT for internal credit
    /// @param to Address of the recipient
    /// @param amount Amount of FIAT to exit [wad]
    function exitMoneta(address to, uint256 amount) public {
        if (to == address(0)) revert LeverActions__exitMoneta_zeroUserAddress();

        // proxy needs to delegate ability to transfer internal credit on its behalf to Moneta first
        if (codex.delegates(address(this), address(moneta)) != 1) codex.grantDelegate(address(moneta));

        moneta.exit(to, amount);
    }

    /// @dev The user needs to previously call approveFIAT with the address of Moneta as the spender
    /// @param from Address of the account which provides FIAT
    /// @param amount Amount of FIAT to enter [wad]
    function enterMoneta(address from, uint256 amount) public {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) fiat.transferFrom(from, address(this), amount);

        moneta.enter(address(this), amount);
    }

    /// @notice Deposits `amount` of `token` with `tokenId` from `from` into the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function enterVault(
        address vault,
        address token,
        uint256 tokenId,
        address from,
        uint256 amount
    ) public virtual;

    /// @notice Withdraws `amount` of `token` with `tokenId` to `to` from the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual;

    function addCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        uint256 addCollateral,
        uint256 addDebt
    ) public {
        // update the interest rate accumulator in Codex for the vault
        if (addDebt != 0) publican.collect(vault);

        // transfer tokens to be used as collateral into Vault
        enterVault(vault, token, tokenId, collateralizer, wmul(uint256(addCollateral), IVault(vault).tokenScale()));

        // compute normal debt and compensate for precision error caused by wdiv
        (, uint256 rate, , ) = codex.vaults(vault);
        uint256 deltaNormalDebt = wdiv(addDebt, rate);
        if (wmul(deltaNormalDebt, rate) < addDebt) deltaNormalDebt = add(deltaNormalDebt, uint256(1));

        // update collateral and debt balances
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            toInt256(addCollateral),
            toInt256(deltaNormalDebt)
        );

        // redeem newly generated internal credit for FIAT
        exitMoneta(creditor, addDebt);
    }

    function subCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        uint256 subCollateral,
        uint256 subNormalDebt
    ) public {
        // update collateral and debt balanaces
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            -toInt256(subCollateral),
            -toInt256(subNormalDebt)
        );

        // withdraw tokens not be used as collateral anymore from Vault
        exitVault(vault, token, tokenId, collateralizer, wmul(subCollateral, IVault(vault).tokenScale()));
    }

    function _sellFIATExactIn(SellFIATSwapParams memory params, uint256 exactAmountIn) internal returns (uint256) {
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            fiatPoolId,
            IBalancerVault.SwapKind.GIVEN_IN,
            address(fiat),
            params.assetOut,
            exactAmountIn,
            new bytes(0)
        );
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );

        return IBalancerVault(fiatBalancerVault).swap(singleSwap, funds, params.minAmountOut, params.deadline);
    }

    function _buyFIATExactOut(BuyFIATSwapParams memory params, uint256 exactAmountOut) internal returns (uint256) {
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            fiatPoolId,
            IBalancerVault.SwapKind.GIVEN_OUT,
            params.assetIn,
            address(fiat),
            exactAmountOut,
            new bytes(0)
        );
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );

        return IBalancerVault(fiatBalancerVault).swap(singleSwap, funds, params.maxAmountIn, params.deadline);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {IFlash, ICreditFlashBorrower, IERC3156FlashBorrower} from "fiat/interfaces/IFlash.sol";
import {IPublican} from "fiat/interfaces/IPublican.sol";
import {WAD, toInt256, add, wmul, wdiv, sub} from "fiat/utils/Math.sol";

import {Lever20Actions} from "./Lever20Actions.sol";
import {IPeriphery, IDivider, IAdapter} from "../vault/VaultSPTActions.sol";

interface ISenseSpace {
    function decimals() external view returns (uint256);

    struct SwapRequest {
        IBalancerVault.SwapKind kind;
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function pti() external view returns (uint256);
}

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            ERC20[] memory tokens,
            uint256[] memory balances,
            uint256 maxBlockNumber
        );
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title LeverSPTActions
/// @notice A set of vault actions for modifying positions collateralized by Sense Finance pTokens
contract LeverSPTActions is Lever20Actions, ICreditFlashBorrower, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    /// @notice Address of the Sense Finance Periphery
    IPeriphery public immutable periphery;
    /// @notice Address of the Sense Finance Divider
    IDivider public immutable divider;

    /// ======== Custom Errors ======== ///

    error LeverSPTActions__onFlashLoan_unknownSender();
    error LeverSPTActions__onFlashLoan_unknownToken();
    error LeverSPTActions__onFlashLoan_nonZeroFee();
    error LeverSPTActions__onFlashLoan_unsupportedAction();
    error LeverSPTActions__onCreditFlashLoan_unknownSender();
    error LeverSPTActions__onCreditFlashLoan_nonZeroFee();
    error LeverSPTActions__onCreditFlashLoan_unsupportedAction();

    /// ======== Types ======== ///

    struct CollateralSwapParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Min amount of  [tokenScale for buying and selling]
        uint256 minAccepted;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the asset to be swapped for `assetOut`, `underlierToken` for buying, `collateral` for selling
        address assetIn;
        // Address of the asset to receive in ex. for `assetIn`, `collateral` for buying, `underlierToken` for selling
        address assetOut;
        // Amount of `assetIn` to approve for the Sense Finance Periphery for swapping `assetIn` for `assetOut`
        uint256 approve;
    }

    struct PTokenRedeemParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the pToken's yield source
        address target;
        // Address of the pToken's underlier
        address underlierToken;
        // Amount of `target` token to approve for the Sense Finance Adapter for unwrapping them for `underlierToken`
        uint256 approveTarget;
    }

    struct BuyCollateralAndIncreaseLeverFlashLoanData {
        // Address of the collateral vault
        address vault;
        // Address of the collateral token
        address token;
        // Address of the owner of the position
        address position;
        // Amount of underliers the user provides (directly impacts the health factor) [underlierScale]
        uint256 upfrontUnderliers;
        // Swap config for the FIAT to underlier swap
        SellFIATSwapParams fiatSwapParams;
        // Swap config for the underlier to collateral token swap
        CollateralSwapParams collateralSwapParams;
    }

    struct SellCollateralAndDecreaseLeverFlashLoanData {
        // Address of the collateral vault
        address vault;
        // Address of the collateral token
        address token;
        // Address of the owner of the position
        address position;
        // Address of the account who receives the withdrawn / swapped underliers
        address collateralizer;
        // Amount of pTokens to withdraw and swap for underliers [tokenScale]
        uint256 subPTokenAmount;
        // Swap config for the underlier to FIAT swap
        BuyFIATSwapParams fiatSwapParams;
        // Swap config for the pToken to underlier swap
        CollateralSwapParams collateralSwapParams;
    }

    struct RedeemCollateralAndDecreaseLeverFlashLoanData {
        // Address of the collateral vault
        address vault;
        // Address of the collateral token
        address token;
        // Address of the owner of the position
        address position;
        // Address of the account who receives the withdrawn / swapped underliers
        address collateralizer;
        // Amount of pTokens to withdraw and swap for underliers [tokenScale]
        uint256 subPTokenAmount;
        // Swap config for the underlier to FIAT swap
        BuyFIATSwapParams fiatSwapParams;
        // Config for the redemption of pToken for underlier
        PTokenRedeemParams redeemParams;
    }

    constructor(
        address codex,
        address fiat,
        address flash,
        address moneta,
        address publican,
        bytes32 fiatPoolId,
        address fiatBalancerVault,
        address periphery_,
        address divider_
    ) Lever20Actions(codex, fiat, flash, moneta, publican, fiatPoolId, fiatBalancerVault) {
        periphery = IPeriphery(periphery_);
        divider = IDivider(divider_);
    }

    /// ======== Position Management ======== ///

    /// @notice Increases the leverage factor of a position by flash minting `addDebt` amount of FIAT
    /// and selling it on top of the `underlierAmount` the `collateralizer` provided for more pTokens.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account who puts up the upfront amount of underliers
    /// @param upfrontUnderliers Amount of underliers the `collateralizer` puts up upfront [underlierScale]
    /// @param addDebt Amount of debt to generate in total [wad]
    /// @param fiatSwapParams Parameters of the flash lent FIAT to underlier swap
    /// @param collateralSwapParams Parameters of the underlier to pToken swap
    function buyCollateralAndIncreaseLever(
        address vault,
        address position,
        address collateralizer,
        uint256 upfrontUnderliers,
        uint256 addDebt,
        SellFIATSwapParams calldata fiatSwapParams,
        CollateralSwapParams calldata collateralSwapParams
    ) public {
        // if `collateralizer` is set to an external address then transfer the amount directly to Action contract
        // requires `collateralizer` to have set an allowance for the proxy
        if (collateralizer == address(this) || collateralizer == address(0)) {
            IERC20(collateralSwapParams.assetIn).safeTransfer(address(self), upfrontUnderliers);
        } else {
            IERC20(collateralSwapParams.assetIn).safeTransferFrom(collateralizer, address(self), upfrontUnderliers);
        }

        codex.grantDelegate(self);

        bytes memory data = abi.encode(
            FlashLoanData(
                1,
                abi.encode(
                    BuyCollateralAndIncreaseLeverFlashLoanData(
                        vault,
                        collateralSwapParams.assetOut,
                        position,
                        upfrontUnderliers,
                        fiatSwapParams,
                        collateralSwapParams
                    )
                )
            )
        );

        flash.flashLoan(IERC3156FlashBorrower(address(self)), address(fiat), addDebt, data);

        codex.revokeDelegate(self);
    }

    /// @notice `buyCollateralAndIncreaseLever` flash loan callback
    /// @dev Executed in the context of LeverSPTActions instead of the Proxy
    function onFlashLoan(
        address, /* initiator */
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(flash)) revert LeverSPTActions__onFlashLoan_unknownSender();
        if (token != address(fiat)) revert LeverSPTActions__onFlashLoan_unknownToken();
        if (fee != 0) revert LeverSPTActions__onFlashLoan_nonZeroFee();

        FlashLoanData memory params = abi.decode(data, (FlashLoanData));
        if (params.action != 1) revert LeverSPTActions__onFlashLoan_unsupportedAction();
        _onBuyCollateralAndIncreaseLever(amount, params.data);

        // payback
        fiat.approve(address(flash), amount);

        return CALLBACK_SUCCESS;
    }

    function _onBuyCollateralAndIncreaseLever(uint256 borrowed, bytes memory data) internal {
        BuyCollateralAndIncreaseLeverFlashLoanData memory params = abi.decode(
            data,
            (BuyCollateralAndIncreaseLeverFlashLoanData)
        );

        // sell fiat for underlier
        uint256 underlierAmount = _sellFIATExactIn(params.fiatSwapParams, borrowed);

        // sum underlier from sender and underliers from fiat swap
        underlierAmount = add(underlierAmount, params.upfrontUnderliers);

        // sell underlier for collateral token
        uint256 pTokenSwapped = _buyPToken(underlierAmount, params.collateralSwapParams);
        uint256 addCollateral = wdiv(pTokenSwapped, IVault(params.vault).tokenScale());

        // update position and mint fiat
        addCollateralAndDebt(
            params.vault,
            params.token,
            0,
            params.position,
            address(this),
            address(this),
            addCollateral,
            borrowed
        );
    }

    /// @notice Decreases the leverage factor of a position by flash lending `subNormalDebt * rate` amount of FIAT
    /// to decrease the outstanding debt (incl. interest), selling the withdrawn collateral (pToken) of the position
    /// for underliers and selling a portion of the underliers for FIAT to repay the flash lent amount.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account receives the excess collateral (pToken)
    /// @param subPTokenAmount Amount of pToken to withdraw from the position [tokenScale]
    /// @param subNormalDebt Amount of normalized debt of the position to reduce [wad]
    /// @param fiatSwapParams Parameters of the underlier to FIAT swap
    /// @param collateralSwapParams Parameters of the pToken to underlier swap
    function sellCollateralAndDecreaseLever(
        address vault,
        address position,
        address collateralizer,
        uint256 subPTokenAmount,
        uint256 subNormalDebt,
        BuyFIATSwapParams calldata fiatSwapParams,
        CollateralSwapParams calldata collateralSwapParams
    ) public {
        codex.grantDelegate(self);

        bytes memory data = abi.encode(
            FlashLoanData(
                2,
                abi.encode(
                    SellCollateralAndDecreaseLeverFlashLoanData(
                        vault,
                        collateralSwapParams.assetIn,
                        position,
                        collateralizer,
                        subPTokenAmount,
                        fiatSwapParams,
                        collateralSwapParams
                    )
                )
            )
        );

        // update the interest rate accumulator in Codex for the vault
        if (subNormalDebt != 0) publican.collect(vault);
        // add due interest from normal debt
        (, uint256 rate, , ) = codex.vaults(vault);
        flash.creditFlashLoan(ICreditFlashBorrower(address(self)), wmul(rate, subNormalDebt), data);

        codex.revokeDelegate(self);
    }

    /// @notice Decreases the leverage factor of a position by flash lending `subNormalDebt * rate` amount of FIAT
    /// to decrease the outstanding debt (incl. interest), redeeming the withdrawn collateral (pToken) of the position
    /// for underliers and selling a portion of the underliers for FIAT to repay the flash lent amount.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account receives the excess collateral (redeemed underliers)
    /// @param subPTokenAmount Amount of pToken to withdraw from the position [tokenScale]
    /// @param subNormalDebt Amount of normalized debt of the position to reduce [wad]
    /// @param fiatSwapParams Parameters of the underlier to FIAT swap
    /// @param redeemParams Parameters for redeeming pToken
    function redeemCollateralAndDecreaseLever(
        address vault,
        address token,
        address position,
        address collateralizer,
        uint256 subPTokenAmount,
        uint256 subNormalDebt,
        BuyFIATSwapParams calldata fiatSwapParams,
        PTokenRedeemParams calldata redeemParams
    ) public {
        codex.grantDelegate(self);

        bytes memory data = abi.encode(
            FlashLoanData(
                3,
                abi.encode(
                    RedeemCollateralAndDecreaseLeverFlashLoanData(
                        vault,
                        token,
                        position,
                        collateralizer,
                        subPTokenAmount,
                        fiatSwapParams,
                        redeemParams
                    )
                )
            )
        );

        // update the interest rate accumulator in Codex for the vault
        if (subNormalDebt != 0) publican.collect(vault);
        // add due interest from normal debt
        (, uint256 rate, , ) = codex.vaults(vault);
        flash.creditFlashLoan(ICreditFlashBorrower(address(self)), wmul(rate, subNormalDebt), data);

        codex.revokeDelegate(self);
    }

    /// @notice `sellCollateralAndDecreaseLever` and `redeemCollateralAndDecreaseLever` flash loan callback
    /// @dev Executed in the context of LeverSPTActions instead of the Proxy
    function onCreditFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(flash)) revert LeverSPTActions__onCreditFlashLoan_unknownSender();
        if (fee != 0) revert LeverSPTActions__onCreditFlashLoan_nonZeroFee();

        FlashLoanData memory params = abi.decode(data, (FlashLoanData));
        if (params.action == 2) _onSellCollateralAndDecreaseLever(initiator, amount, params.data);
        else if (params.action == 3) _onRedeemCollateralAndDecreaseLever(initiator, amount, params.data);
        else revert LeverSPTActions__onCreditFlashLoan_unsupportedAction();

        // payback
        fiat.approve(address(moneta), amount);
        moneta.enter(address(this), amount);
        codex.transferCredit(address(this), address(flash), amount);

        return CALLBACK_SUCCESS_CREDIT;
    }

    function _onSellCollateralAndDecreaseLever(
        address initiator,
        uint256 borrowed,
        bytes memory data
    ) internal {
        SellCollateralAndDecreaseLeverFlashLoanData memory params = abi.decode(
            data,
            (SellCollateralAndDecreaseLeverFlashLoanData)
        );

        // pay back debt of position
        subCollateralAndDebt(
            params.vault,
            params.token,
            0,
            params.position,
            address(this),
            wdiv(params.subPTokenAmount, IVault(params.vault).tokenScale()),
            borrowed
        );

        // sell collateral for underlier
        uint256 underlierAmount = _sellPToken(params.subPTokenAmount, params.collateralSwapParams);

        // sell part of underlier for FIAT
        uint256 underlierSwapped = _buyFIATExactOut(params.fiatSwapParams, borrowed);

        // send underlier to collateralizer
        IERC20(params.collateralSwapParams.assetOut).safeTransfer(
            (params.collateralizer == address(0)) ? initiator : params.collateralizer,
            sub(underlierAmount, underlierSwapped)
        );
    }

    function _onRedeemCollateralAndDecreaseLever(
        address initiator,
        uint256 borrowed,
        bytes memory data
    ) internal {
        RedeemCollateralAndDecreaseLeverFlashLoanData memory params = abi.decode(
            data,
            (RedeemCollateralAndDecreaseLeverFlashLoanData)
        );

        // pay back debt of position
        subCollateralAndDebt(
            params.vault,
            params.token,
            0,
            params.position,
            address(this),
            wdiv(params.subPTokenAmount, IVault(params.vault).tokenScale()),
            borrowed
        );

        // redeem pTokens for `target` token
        uint256 targetAmount = divider.redeem(
            params.redeemParams.adapter,
            params.redeemParams.maturity,
            params.subPTokenAmount
        );

        // approve the Sense Finance Adapter to transfer `target` tokens
        if (params.redeemParams.approveTarget != 0) {
            IERC20(params.redeemParams.target).approve(params.redeemParams.adapter, targetAmount);
        }
        // unwrap `target` token for underlier
        uint256 underlierAmount = IAdapter(params.redeemParams.adapter).unwrapTarget(targetAmount);

        // sell part of underlier for FIAT
        uint256 underlierSwapped = _buyFIATExactOut(params.fiatSwapParams, borrowed);

        // send underlier to collateralizer
        IERC20(params.fiatSwapParams.assetIn).safeTransfer(
            (params.collateralizer == address(0)) ? initiator : params.collateralizer,
            sub(underlierAmount, underlierSwapped)
        );
    }

    /// @dev Executed in the context of LeverEPTActions instead of the Proxy
    function _buyPToken(uint256 underlierAmount, CollateralSwapParams memory swapParams) internal returns (uint256) {
        if (IERC20(swapParams.assetIn).allowance(address(this), address(periphery)) < underlierAmount) {
            IERC20(swapParams.assetIn).approve(address(periphery), type(uint256).max);
        }

        return
            periphery.swapUnderlyingForPTs(
                swapParams.adapter,
                swapParams.maturity,
                underlierAmount,
                swapParams.minAccepted
            );
    }

    /// @dev Executed in the context of LeverEPTActions instead of the Proxy
    function _sellPToken(uint256 pTokenAmount, CollateralSwapParams memory swapParams) internal returns (uint256) {
        if (IERC20(swapParams.assetIn).allowance(address(this), address(periphery)) < pTokenAmount) {
            IERC20(swapParams.assetIn).approve(address(periphery), type(uint256).max);
        }

        return
            periphery.swapPTsForUnderlying(
                swapParams.adapter,
                swapParams.maturity,
                pTokenAmount,
                swapParams.minAccepted
            );
    }

    /// ======== View Methods ======== ///

    /// @notice Returns an amount of pToken for a given an amount of the pTokens underlier token (e.g. USDC)
    /// @param senseSpace Address of the Sense Finance (pToken / target) Balancer V2 Pool
    /// @param balancerVault Address of the Balancer V2 vault
    /// @param underlierAmount Amount of underliers to swap for pTokens [underlierScale]
    /// @return Amount of pToken [tokenScale]
    function underlierToPToken(address senseSpace, address balancerVault, uint256 underlierAmount) external view returns (uint256) {
        ISenseSpace space = ISenseSpace(senseSpace);
        bytes32 poolId = space.getPoolId();
        (ERC20[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        uint256 pTokenIndex = space.pti();
        uint256 targetIndex = sub(1, pTokenIndex);
        ERC20 target = tokens[targetIndex];
        uint256 targetAmount = IERC4626(address(target)).previewDeposit(underlierAmount);
        return
            space.onSwap(
                ISenseSpace.SwapRequest(
                    IBalancerVault.SwapKind.GIVEN_IN,
                    target,
                    tokens[pTokenIndex],
                    targetAmount,
                    poolId,
                    0,
                    address(0),
                    address(0),
                    ""
                ),
                balances[targetIndex],
                balances[pTokenIndex]
            );
    }

    /// @notice Returns an amount of the pTokens underlier token for a given an amount of pToken (e.g. USDC pToken)
    /// @param senseSpace Address of the Sense Finance (pToken / target) Balancer V2 Pool
    /// @param balancerVault Address of the Balancer V2 vault
    /// @param pTokenAmount Amount of pToken to swap for underliers [tokenScale]
    /// @return Amount of underlier [underlierScale]
    function pTokenToUnderlier(address senseSpace, address balancerVault, uint256 pTokenAmount) external view returns (uint256) {
        ISenseSpace space = ISenseSpace(senseSpace);
        bytes32 poolId = space.getPoolId();
        (ERC20[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        uint256 pTokenIndex = space.pti();
        uint256 targetIndex = sub(1, pTokenIndex);
        ERC20 target = tokens[targetIndex];
        uint256 targetAmount = space.onSwap(
            ISenseSpace.SwapRequest(
                IBalancerVault.SwapKind.GIVEN_IN,
                tokens[pTokenIndex],
                target,
                pTokenAmount,
                poolId,
                0,
                address(0),
                address(0),
                ""
            ),
            balances[pTokenIndex],
            balances[targetIndex]
        );
        return IERC4626(address(target)).previewRedeem(targetAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {WAD, toInt256, mul, div, wmul, wdiv} from "fiat/utils/Math.sol";

import {VaultActions} from "./VaultActions.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Vault20Actions
/// @notice A set of vault actions for modifying positions collateralized by ERC20 tokens
contract Vault20Actions is VaultActions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultActions__enterVault_zeroVaultAddress();
    error VaultActions__enterVault_zeroTokenAddress();
    error VaultActions__exitVault_zeroVaultAddress();
    error VaultActions__exitVault_zeroTokenAddress();
    error VaultActions__exitVault_zeroToAddress();

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_
    ) VaultActions(codex_, moneta_, fiat_, publican_) {}

    /// @notice Deposits amount of `token` with `tokenId` from `from` into the `vault`
    /// @dev Implements virtual method defined in VaultActions for ERC20 tokens
    /// @param vault Address of the Vault to enter
    /// @param token Address of the collateral token
    /// @param *tokenId ERC1155 TokenId (leave empty for ERC20 tokens)
    /// @param from Address from which to take the deposit from
    /// @param amount Amount of collateral tokens to deposit [tokenScale]
    function enterVault(
        address vault,
        address token,
        uint256, /* tokenId */
        address from,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert VaultActions__enterVault_zeroVaultAddress();
        if (token == address(0)) revert VaultActions__enterVault_zeroTokenAddress();

        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }

        IERC20(token).approve(vault, amount);
        IVault(vault).enter(0, address(this), amount);
    }

    /// @notice Withdraws amount of `token` with `tokenId` to `to` from the `vault`
    /// @dev Implements virtual method defined in VaultActions for ERC20 tokens
    /// @param vault Address of the Vault to exit
    /// @param token Address of the collateral token
    /// @param *tokenId ERC1155 TokenId (leave empty for ERC20 tokens)
    /// @param to Address which receives the withdrawn collateral tokens
    /// @param amount Amount of collateral tokens to exit [tokenScale]
    function exitVault(
        address vault,
        address token,
        uint256, /* tokenId */
        address to,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert VaultActions__exitVault_zeroVaultAddress();
        if (token == address(0)) revert VaultActions__exitVault_zeroTokenAddress();
        if (to == address(0)) revert VaultActions__exitVault_zeroToAddress();

        IVault(vault).exit(0, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IPublican} from "fiat/interfaces/IPublican.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {WAD, toInt256, sub, wmul, wdiv} from "fiat/utils/Math.sol";

/// @title VaultActions
/// @notice A set of base vault actions to inherited from
abstract contract VaultActions {
    /// ======== Custom Errors ======== ///

    error VaultActions__exitMoneta_zeroUserAddress();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable codex;
    /// @notice Moneta
    IMoneta public immutable moneta;
    /// @notice FIAT token
    IFIAT public immutable fiat;
    /// @notice Publican
    IPublican public immutable publican;

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_
    ) {
        codex = ICodex(codex_);
        moneta = IMoneta(moneta_);
        fiat = IFIAT(fiat_);
        publican = IPublican(publican_);
    }

    /// @notice Sets `amount` as the allowance of `spender` over the UserProxy's FIAT
    /// @param spender Address of the spender
    /// @param amount Amount of tokens to approve [wad]
    function approveFIAT(address spender, uint256 amount) external {
        fiat.approve(spender, amount);
    }

    /// @dev Redeems FIAT for internal credit
    /// @param to Address of the recipient
    /// @param amount Amount of FIAT to exit [wad]
    function exitMoneta(address to, uint256 amount) public {
        if (to == address(0)) revert VaultActions__exitMoneta_zeroUserAddress();

        // proxy needs to delegate ability to transfer internal credit on its behalf to Moneta first
        if (codex.delegates(address(this), address(moneta)) != 1) codex.grantDelegate(address(moneta));

        moneta.exit(to, amount);
    }

    /// @dev The user needs to previously call approveFIAT with the address of Moneta as the spender
    /// @param from Address of the account which provides FIAT
    /// @param amount Amount of FIAT to enter [wad]
    function enterMoneta(address from, uint256 amount) public {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) fiat.transferFrom(from, address(this), amount);

        moneta.enter(address(this), amount);
    }

    /// @notice Deposits `amount` of `token` with `tokenId` from `from` into the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function enterVault(
        address vault,
        address token,
        uint256 tokenId,
        address from,
        uint256 amount
    ) public virtual;

    /// @notice Withdraws `amount` of `token` with `tokenId` to `to` from the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual;

    /// @notice method for adjusting collateral and debt balances of a position.
    /// 1. updates the interest rate accumulator for the given vault
    /// 2. enters FIAT into Moneta if deltaNormalDebt is negative (applies rate to deltaNormalDebt)
    /// 3. enters Collateral into Vault if deltaCollateral is positive
    /// 3. modifies collateral and debt balances in Codex
    /// 4. exits FIAT from Moneta if deltaNormalDebt is positive (applies rate to deltaNormalDebt)
    /// 5. exits Collateral from Vault if deltaCollateral is negative
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the vault's collateral token
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) for this Position [wad]
    function modifyCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) public {
        // update the interest rate accumulator in Codex for the vault
        if (deltaNormalDebt != 0) publican.collect(vault);

        if (deltaNormalDebt < 0) {
            // add due interest from normal debt
            (, uint256 rate, , ) = codex.vaults(vault);
            enterMoneta(creditor, uint256(-wmul(rate, deltaNormalDebt)));
        }

        // transfer tokens to be used as collateral into Vault
        if (deltaCollateral > 0) {
            enterVault(
                vault,
                token,
                tokenId,
                collateralizer,
                wmul(uint256(deltaCollateral), IVault(vault).tokenScale())
            );
        }

        // update collateral and debt balanaces
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            deltaCollateral,
            deltaNormalDebt
        );

        // redeem newly generated internal credit for FIAT
        if (deltaNormalDebt > 0) {
            // forward all generated credit by applying rate
            (, uint256 rate, , ) = codex.vaults(vault);
            exitMoneta(creditor, wmul(uint256(deltaNormalDebt), rate));
        }

        // withdraw tokens not be used as collateral anymore from Vault
        if (deltaCollateral < 0) {
            exitVault(
                vault,
                token,
                tokenId,
                collateralizer,
                wmul(uint256(-deltaCollateral), IVault(vault).tokenScale())
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {WAD, toInt256, wmul, wdiv, sub} from "fiat/utils/Math.sol";

import {Vault20Actions} from "./Vault20Actions.sol";

interface IPeriphery {
    function swapUnderlyingForPTs(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal);

    function swapPTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 uBal);

    function divider() external view returns (address divider);
}

interface IDivider {
    function redeem(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external returns (uint256 tBal);
}

interface IAdapter {
    function unwrapTarget(uint256 amount) external returns (uint256);
}

interface ISenseSpace {
    function decimals() external view returns (uint256);

    struct SwapRequest {
        IBalancerVault.SwapKind kind;
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function pti() external view returns (uint256);
}

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            ERC20[] memory tokens,
            uint256[] memory balances,
            uint256 maxBlockNumber
        );
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Vault Sense Actions for principal token
/// @notice A set of vault actions for modifying positions collateralized by Sense Finance pTokens
contract VaultSPTActions is Vault20Actions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultSPTActions__buyCollateralAndModifyDebt_zeroUnderlierAmount();
    error VaultSPTActions__sellCollateralAndModifyDebt_zeroPTokenAmount();
    error VaultSPTActions__redeemCollateralAndModifyDebt_zeroPTokenAmount();

    /// ======== Storage ======== ///

    /// @notice Address of the Sense Finance Periphery
    IPeriphery public immutable periphery;
    /// @notice Address of the Sense Finance Divider
    IDivider public immutable divider;

    // Swap data
    struct SwapParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Min amount of  [tokenScale for buying and selling]
        uint256 minAccepted;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the asset to be swapped for `assetOut`, `underlierToken` for buying, `collateral` for selling
        address assetIn;
        // Address of the asset to receive in ex. for `assetOut`, `collateral` for buying, `underlierToken` for selling
        address assetOut;
        // Amount of `assetIn` to approve for the Sense Finance Periphery for swapping `assetIn` for `assetOut`
        uint256 approve;
    }

    struct RedeemParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the pToken's yield source
        address target;
        // Address of the pToken's underlier
        address underlierToken;
        // Amount of `target` token to approve for the Sense Finance Adapter for unwrapping them for `underlierToken`
        uint256 approveTarget;
    }

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_,
        address periphery_,
        address divider_
    ) Vault20Actions(codex_, moneta_, fiat_, publican_) {
        periphery = IPeriphery(periphery_);
        divider = IDivider(divider_);
    }

    /// ======== Position Management ======== ///

    /// @notice Buys pTokens from underliers before it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token.
    /// The underlier is swapped to pTokens token used as collateral.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param underlierAmount Amount of underlier to swap for pTokens to put up for collateral [underlierScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param swapParams Parameters of the underlier to pToken swap
    function buyCollateralAndModifyDebt(
        address vault,
        address position,
        address collateralizer,
        address creditor,
        uint256 underlierAmount,
        int256 deltaNormalDebt,
        SwapParams calldata swapParams
    ) public {
        if (underlierAmount == 0) revert VaultSPTActions__buyCollateralAndModifyDebt_zeroUnderlierAmount();

        // buy pToken from underlier
        uint256 pTokenAmount = _buyPToken(underlierAmount, collateralizer, swapParams);
        int256 deltaCollateral = toInt256(wdiv(pTokenAmount, IVault(vault).tokenScale()));

        // enter pToken and collateralize position
        modifyCollateralAndDebt(
            vault,
            swapParams.assetOut,
            0,
            position,
            address(this),
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );
    }

    /// @notice Sells pTokens for underliers after it modifies a Position's collateral and debt balances
    /// and mints/burns FIAT using the underlier token. This method allows for selling pTokens even after maturity.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param pTokenAmount Amount of pToken to remove as collateral and to swap for underlier [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param swapParams Parameters of the underlier to pToken swap
    function sellCollateralAndModifyDebt(
        address vault,
        address position,
        address collateralizer,
        address creditor,
        uint256 pTokenAmount,
        int256 deltaNormalDebt,
        SwapParams calldata swapParams
    ) public {
        if (pTokenAmount == 0) revert VaultSPTActions__sellCollateralAndModifyDebt_zeroPTokenAmount();

        int256 deltaCollateral = -toInt256(wdiv(pTokenAmount, IVault(vault).tokenScale()));

        // withdraw pToken from the position
        modifyCollateralAndDebt(
            vault,
            swapParams.assetIn,
            0,
            position,
            address(this),
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );

        // sell pToken according to `swapParams`
        uint256 underlier = _sellPToken(pTokenAmount, swapParams);

        // Send underlier to collateralizer
        IERC20(swapParams.assetOut).safeTransfer(collateralizer, underlier);
    }

    /// @notice Redeems pTokens for underliers after it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token. Fails if pToken hasn't matured yet.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the collateral token (pToken)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param pTokenAmount Amount of pToken to remove as collateral and to swap or redeem for underlier [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function redeemCollateralAndModifyDebt(
        address vault,
        address token,
        address position,
        address collateralizer,
        address creditor,
        uint256 pTokenAmount,
        int256 deltaNormalDebt,
        RedeemParams calldata redeemParams
    ) public {
        if (pTokenAmount == 0) revert VaultSPTActions__redeemCollateralAndModifyDebt_zeroPTokenAmount();

        int256 deltaCollateral = -toInt256(wdiv(pTokenAmount, IVault(vault).tokenScale()));

        // withdraw pToken from the position
        modifyCollateralAndDebt(vault, token, 0, position, address(this), creditor, deltaCollateral, deltaNormalDebt);

        // redeem pTokens for `target` token
        uint256 targetAmount = divider.redeem(redeemParams.adapter, redeemParams.maturity, pTokenAmount);

        // approve the Sense Finance Adapter to transfer `target` tokens on behalf of the proxy
        if (redeemParams.approveTarget != 0) {
            IERC20(redeemParams.target).approve(redeemParams.adapter, targetAmount);
        }
        // unwrap `target` token for underlier
        uint256 underlierAmount = IAdapter(redeemParams.adapter).unwrapTarget(targetAmount);

        // send underlier to collateralizer
        IERC20(redeemParams.underlierToken).safeTransfer(collateralizer, underlierAmount);
    }

    function _buyPToken(
        uint256 underlierAmount,
        address from,
        SwapParams calldata swapParams
    ) internal returns (uint256) {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC20(swapParams.assetIn).safeTransferFrom(from, address(this), underlierAmount);
        }

        // approve Sense Finance Periphery to transfer underliers on behalf of proxy
        if (swapParams.approve != 0) {
            IERC20(swapParams.assetIn).approve(address(periphery), swapParams.approve);
        }

        return
            periphery.swapUnderlyingForPTs(
                swapParams.adapter,
                swapParams.maturity,
                underlierAmount,
                swapParams.minAccepted
            );
    }

    function _sellPToken(uint256 pTokenAmount, SwapParams calldata swapParams) internal returns (uint256) {
        // approve Sense Finance Periphery to transfer pTokens on behalf of the proxy
        if (swapParams.approve != 0) {
            IERC20(swapParams.assetIn).approve(address(periphery), swapParams.approve);
        }

        return
            periphery.swapPTsForUnderlying(
                swapParams.adapter,
                swapParams.maturity,
                pTokenAmount,
                swapParams.minAccepted
            );
    }

    /// ======== View Methods ======== ///

    /// @notice Returns an amount of pToken for a given an amount of the pTokens underlier token (e.g. USDC)
    /// @param senseSpace Address of the Sense Finance (pToken / target) Balancer V2 Pool
    /// @param balancerVault Address of the Balancer V2 vault
    /// @param underlierAmount Amount of underliers to swap for pTokens [underlierScale]
    /// @return Amount of pToken [tokenScale]
    function underlierToPToken(address senseSpace, address balancerVault, uint256 underlierAmount) external view returns (uint256) {
        ISenseSpace space = ISenseSpace(senseSpace);
        bytes32 poolId = space.getPoolId();
        (ERC20[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        uint256 pTokenIndex = space.pti();
        uint256 targetIndex = sub(1, pTokenIndex);
        ERC20 target = tokens[targetIndex];
        uint256 targetAmount = IERC4626(address(target)).previewDeposit(underlierAmount);
        return
            space.onSwap(
                ISenseSpace.SwapRequest(
                    IBalancerVault.SwapKind.GIVEN_IN,
                    target,
                    tokens[pTokenIndex],
                    targetAmount,
                    poolId,
                    0,
                    address(0),
                    address(0),
                    ""
                ),
                balances[targetIndex],
                balances[pTokenIndex]
            );
    }

    /// @notice Returns an amount of the pTokens underlier token for a given an amount of pToken (e.g. USDC pToken)
    /// @param senseSpace Address of the Sense Finance (pToken / target) Balancer V2 Pool
    /// @param balancerVault Address of the Balancer V2 vault
    /// @param pTokenAmount Amount of pToken to swap for underliers [tokenScale]
    /// @return Amount of underlier [underlierScale]
    function pTokenToUnderlier(address senseSpace, address balancerVault, uint256 pTokenAmount) external view returns (uint256) {
        ISenseSpace space = ISenseSpace(senseSpace);
        bytes32 poolId = space.getPoolId();
        (ERC20[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        uint256 pTokenIndex = space.pti();
        uint256 targetIndex = sub(1, pTokenIndex);
        ERC20 target = tokens[targetIndex];
        uint256 targetAmount = space.onSwap(
            ISenseSpace.SwapRequest(
                IBalancerVault.SwapKind.GIVEN_IN,
                tokens[pTokenIndex],
                target,
                pTokenAmount,
                poolId,
                0,
                address(0),
                address(0),
                ""
            ),
            balances[pTokenIndex],
            balances[targetIndex]
        );
        return IERC4626(address(target)).previewRedeem(targetAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";
import {IDebtAuction} from "./IDebtAuction.sol";
import {ISurplusAuction} from "./ISurplusAuction.sol";

interface IAer {
    function codex() external view returns (ICodex);

    function surplusAuction() external view returns (ISurplusAuction);

    function debtAuction() external view returns (IDebtAuction);

    function debtQueue(uint256) external view returns (uint256);

    function queuedDebt() external view returns (uint256);

    function debtOnAuction() external view returns (uint256);

    function auctionDelay() external view returns (uint256);

    function debtAuctionSellSize() external view returns (uint256);

    function debtAuctionBidSize() external view returns (uint256);

    function surplusAuctionSellSize() external view returns (uint256);

    function surplusBuffer() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function queueDebt(uint256 debt) external;

    function unqueueDebt(uint256 queuedAt) external;

    function settleDebtWithSurplus(uint256 debt) external;

    function settleAuctionedDebt(uint256 debt) external;

    function startDebtAuction() external returns (uint256 auctionId);

    function startSurplusAuction() external returns (uint256 auctionId);

    function transferCredit(address to, uint256 credit) external;

    function lock() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function live() external view returns (uint256);

    function lock() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";

interface IPriceFeed {
    function peek() external returns (bytes32, bool);

    function read() external view returns (bytes32);
}

interface ICollybus {
    function vaults(address) external view returns (uint128, uint128);

    function spots(address) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function rateIds(address, uint256) external view returns (uint256);

    function redemptionPrice() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external;

    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external;

    function updateDiscountRate(uint256 rateId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;

    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view returns (uint256 price);

    function lock() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICodex} from "./ICodex.sol";

interface IDebtAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function tokenToSellBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function aer() external view returns (address);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(
        address recipient,
        uint256 tokensToSell,
        uint256 bid
    ) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 tokensToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock() external;

    function cancelAuction(uint256 id) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IERC20Metadata} from "openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFIATExcl {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

interface IFIAT is IFIATExcl, IERC20, IERC20Permit, IERC20Metadata {}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
pragma solidity ^0.8.4;

import "./ICodex.sol";
import "./IFIAT.sol";
import "./IMoneta.sol";

interface IERC3156FlashBorrower {
    /// @dev Receive `amount` of `token` from the flash lender
    /// @param initiator The initiator of the loan
    /// @param token The loan currency
    /// @param amount The amount of tokens lent
    /// @param fee The additional amount of tokens to repay
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    /// @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {
    /// @dev The amount of currency available to be lent
    /// @param token The loan currency
    /// @return The amount of `token` that can be borrowed
    function maxFlashLoan(address token) external view returns (uint256);

    /// @dev The fee to be charged for a given loan
    /// @param token The loan currency
    /// @param amount The amount of tokens lent
    /// @return The amount of `token` to be charged for the loan, on top of the returned principal
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /// @dev Initiate a flash loan
    /// @param receiver The receiver of the tokens in the loan, and the receiver of the callback
    /// @param token The loan currency
    /// @param amount The amount of tokens lent
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface ICreditFlashBorrower {
    /// @dev Receives `amount` of internal Credit from the Credit flash lender
    /// @param initiator The initiator of the loan
    /// @param amount The amount of tokens lent [wad]
    /// @param fee The additional amount of tokens to repay [wad]
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return The keccak256 hash of "ICreditFlashLoanReceiver.onCreditFlashLoan"
    function onCreditFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface ICreditFlashLender {
    /// @notice Flash lends internal Credit to `receiver`
    /// @dev Reverts if `Flash` gets reentered in the same transaction
    /// @param receiver Address of the receiver of the flash loan [ICreditFlashBorrower]
    /// @param amount Amount of `token` to borrow [wad]
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    /// @return true if flash loan
    function creditFlashLoan(
        ICreditFlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IFlash is IERC3156FlashLender, ICreditFlashLender {
    function codex() external view returns (ICodex);

    function moneta() external view returns (IMoneta);

    function fiat() external view returns (IFIAT);

    function max() external view returns (uint256);

    function CALLBACK_SUCCESS() external view returns (bytes32);

    function CALLBACK_SUCCESS_CREDIT() external view returns (bytes32);

    function setParam(bytes32 param, uint256 data) external;

    function maxFlashLoan(address token) external view override returns (uint256);

    function flashFee(address token, uint256 amount) external view override returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function creditFlashLoan(
        ICreditFlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";
import {IFIAT} from "./IFIAT.sol";

interface IMoneta {
    function codex() external view returns (ICodex);

    function fiat() external view returns (IFIAT);

    function live() external view returns (uint256);

    function lock() external;

    function enter(address user, uint256 amount) external;

    function exit(address user, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";
import {IAer} from "./IAer.sol";

interface IPublican {
    function vaults(address vault) external view returns (uint256, uint256);

    function codex() external view returns (ICodex);

    function aer() external view returns (IAer);

    function baseInterest() external view returns (uint256);

    function init(address vault) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function virtualRate(address vault) external returns (uint256 rate);

    function collect(address vault) external returns (uint256 rate);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICodex} from "./ICodex.sol";

interface ISurplusAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(uint256 creditToSell, uint256 bid) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 creditToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock(uint256 credit) external;

    function cancelAuction(uint256 id) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";
import {ICollybus} from "./ICollybus.sol";

interface IVault {
    function codex() external view returns (ICodex);

    function collybus() external view returns (ICollybus);

    function token() external view returns (address);

    function tokenScale() external view returns (uint256);

    function underlierToken() external view returns (address);

    function underlierScale() external view returns (uint256);

    function vaultType() external view returns (bytes32);

    function live() external view returns (uint256);

    function lock() external;

    function setParam(bytes32 param, address data) external;

    function maturity(uint256 tokenId) external view returns (uint256);

    function fairPrice(
        uint256 tokenId,
        bool net,
        bool face
    ) external view returns (uint256);

    function enter(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;

    function exit(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
pragma solidity ^0.8.4;

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */