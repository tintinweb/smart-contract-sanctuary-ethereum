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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "./ISSVRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISSVNetwork {
    /**
     * @dev Emitted when the account has been enabled.
     * @param ownerAddress Operator's owner.
     */
    event AccountEnable(address indexed ownerAddress);

    /**
     * @dev Emitted when the account has been liquidated.
     * @param ownerAddress Operator's owner.
     */
    event AccountLiquidation(address indexed ownerAddress);

    /**
     * @dev Emitted when the operator has been added.
     * @param id operator's ID.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee Operator's initial fee.
     */
    event OperatorRegistration(
        uint32 indexed id,
        string name,
        address indexed ownerAddress,
        bytes publicKey,
        uint256 fee
    );

    /**
     * @dev Emitted when the operator has been removed.
     * @param operatorId operator's ID.
     * @param ownerAddress Operator's owner.
     */
    event OperatorRemoval(uint32 operatorId, address indexed ownerAddress);

    event OperatorFeeDeclaration(
        address indexed ownerAddress,
        uint32 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    event DeclaredOperatorFeeCancelation(address indexed ownerAddress, uint32 operatorId);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeExecution(
        address indexed ownerAddress,
        uint32 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param operatorId operator's ID.
     * @param ownerAddress Operator's owner.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdate(
        uint32 operatorId,
        address indexed ownerAddress,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operators public keys list for this validator.
     * @param sharesPublicKeys The shared publick keys list for this validator.
     * @param encryptedKeys The encrypted keys list for this validator.
     */
    event ValidatorRegistration(
        address indexed ownerAddress,
        bytes publicKey,
        uint32[] operatorIds,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator is removed.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorRemoval(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an owner deposits funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     * @param senderAddress Sender's address.
     */
    event FundsDeposit(uint256 value, address indexed ownerAddress, address indexed senderAddress);

    /**
     * @dev Emitted when an owner withdraws funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     */
    event FundsWithdrawal(uint256 value, address indexed ownerAddress);

    /**
     * @dev Emitted when the network fee is updated.
     * @param oldFee The old fee
     * @param newFee The new fee
     */
    event NetworkFeeUpdate(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when transfer fees are withdrawn.
     * @param value The amount of tokens withdrawn.
     * @param recipient The recipient address.
     */
    event NetworkFeesWithdrawal(uint256 value, address recipient);

    event DeclareOperatorFeePeriodUpdate(uint256 value);

    event ExecuteOperatorFeePeriodUpdate(uint256 value);

    event LiquidationThresholdPeriodUpdate(uint256 value);

    event OperatorFeeIncreaseLimitUpdate(uint256 value);

    event ValidatorsPerOperatorLimitUpdate(uint256 value);

    event RegisteredOperatorsPerAccountLimitUpdate(uint256 value);

    event MinimumBlocksBeforeLiquidationUpdate(uint256 value);

    event OperatorMaxFeeIncreaseUpdate(uint256 value);

    /** errors */
    error ValidatorWithPublicKeyNotExist();
    error CallerNotValidatorOwner();
    error OperatorWithPublicKeyNotExist();
    error CallerNotOperatorOwner();
    error FeeTooLow();
    error FeeExceedsIncreaseLimit();
    error NoPendingFeeChangeRequest();
    error ApprovalNotWithinTimeframe();
    error NotEnoughBalance();
    error BurnRatePositive();
    error AccountAlreadyEnabled();
    error NegativeBalance();
    error BelowMinimumBlockPeriod();
    error ExceedManagingOperatorsPerAccountLimit();

    /**
     * @dev Initializes the contract.
     * @param registryAddress_ The registry address.
     * @param token_ The network token.
     * @param minimumBlocksBeforeLiquidation_ The minimum blocks before liquidation.
     * @param declareOperatorFeePeriod_ The period an operator needs to wait before they can approve their fee.
     * @param executeOperatorFeePeriod_ The length of the period in which an operator can approve their fee.
     */
    function initialize(
        ISSVRegistry registryAddress_,
        IERC20 token_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint64 operatorMaxFeeIncrease_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_
    ) external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param publicKey Operator's public key. Used to encrypt secret shares of validators keys.
     */
    function registerOperator(
        string calldata name,
        bytes calldata publicKey,
        uint256 fee
    ) external returns (uint32);

    /**
     * @dev Removes an operator.
     * @param operatorId Operator's id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Set operator's fee change request by public key.
     * @param operatorId Operator's id.
     * @param operatorFee The operator's updated fee.
     */
    function declareOperatorFee(uint32 operatorId, uint256 operatorFee) external;

    function cancelDeclaredOperatorFee(uint32 operatorId) external;

    function executeOperatorFee(uint32 operatorId) external;

    /**
     * @dev Updates operator's score by public key.
     * @param operatorId Operator's id.
     * @param score The operators's updated score.
     */
    function updateOperatorScore(uint32 operatorId, uint32 score) external;

    /**
     * @dev Registers a new validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     * @param amount Amount of tokens to deposit.
     */
    function registerValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted,
        uint256 amount
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     * @param amount Amount of tokens to deposit.
     */
    function updateValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted,
        uint256 amount
    ) external;

    /**
     * @dev Removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    /**
     * @dev Deposits tokens for the sender.
     * @param ownerAddress Owners' addresses.
     * @param tokenAmount Tokens amount.
     */
    function deposit(address ownerAddress, uint256 tokenAmount) external;

    /**
     * @dev Withdraw tokens for the sender.
     * @param tokenAmount Tokens amount.
     */
    function withdraw(uint256 tokenAmount) external;

    /**
     * @dev Withdraw total balance to the sender, deactivating their validators if necessary.
     */
    function withdrawAll() external;

    /**
     * @dev Liquidates multiple owners.
     * @param ownerAddresses Owners' addresses.
     */
    function liquidate(address[] calldata ownerAddresses) external;

    /**
     * @dev Enables msg.sender account.
     * @param amount Tokens amount.
     */
    function reactivateAccount(uint256 amount) external;

    /**
     * @dev Updates the number of blocks left for an owner before they can be liquidated.
     * @param blocks The new value.
     */
    function updateLiquidationThresholdPeriod(uint64 blocks) external;

    /**
     * @dev Updates the maximum fee increase in pecentage.
     * @param newOperatorMaxFeeIncrease The new value.
     */
    function updateOperatorFeeIncreaseLimit(uint64 newOperatorMaxFeeIncrease) external;

    function updateDeclareOperatorFeePeriod(uint64 newDeclareOperatorFeePeriod) external;

    function updateExecuteOperatorFeePeriod(uint64 newExecuteOperatorFeePeriod) external;

    /**
     * @dev Updates the network fee.
     * @param fee the new fee
     */
    function updateNetworkFee(uint256 fee) external;

    /**
     * @dev Withdraws network fees.
     * @param amount Amount to withdraw
     */
    function withdrawNetworkEarnings(uint256 amount) external;

    /**
     * @dev Gets total balance for an owner.
     * @param ownerAddress Owner's address.
     */
    function getAddressBalance(address ownerAddress) external view returns (uint256);

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator's id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    function getOperatorDeclaredFee(uint32 operatorId) external view returns (uint256, uint256, uint256);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator's id.
     */
    function getOperatorFee(uint32 operatorId) external view returns (uint256);

    /**
     * @dev Gets the network fee for an address.
     * @param ownerAddress Owner's address.
     */
    function addressNetworkFee(address ownerAddress) external view returns (uint256);

    /**
     * @dev Returns the burn rate of an owner, returns 0 if negative.
     * @param ownerAddress Owner's address.
     */
    function getAddressBurnRate(address ownerAddress) external view returns (uint256);

    /**
     * @dev Check if an owner is liquidatable.
     * @param ownerAddress Owner's address.
     */
    function isLiquidatable(address ownerAddress) external view returns (bool);

    /**
     * @dev Returns the network fee.
     */
    function getNetworkFee() external view returns (uint256);

    /**
     * @dev Gets the available network earnings
     */
    function getNetworkEarnings() external view returns (uint256);

    /**
     * @dev Returns the number of blocks left for an owner before they can be liquidated.
     */
    function getLiquidationThresholdPeriod() external view returns (uint256);

    /**
     * @dev Returns the maximum fee increase in pecentage
     */
     function getOperatorFeeIncreaseLimit() external view returns (uint256);

     function getExecuteOperatorFeePeriod() external view returns (uint256);

     function getDeclaredOperatorFeePeriod() external view returns (uint256);

     function validatorsPerOperatorCount(uint32 operatorId) external view returns (uint32);
}

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        uint32 operatorId;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /** errors */
    error ExceedRegisteredOperatorsByAccountLimit();
    error OperatorDeleted();
    error ValidatorAlreadyExists();
    error ExceedValidatorLimit();
    error OperatorNotFound();
    error InvalidPublicKeyLength();
    error OessDataStructureInvalid();

    /**
     * @dev Initializes the contract
     */
    function initialize() external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint64 fee) external returns (uint32);

    /**
     * @dev removes an operator.
     * @param operatorId Operator id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param fee New operator fee.
     */
    function updateOperatorFee(
        uint32 operatorId,
        uint64 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param score New score.
     */
    function updateOperatorScore(
        uint32 operatorId,
        uint32 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator ids.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted
    ) external;

    /**
     * @dev removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    function enableOwnerValidators(address ownerAddress) external;

    function disableOwnerValidators(address ownerAddress) external;

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operator's owner.
     * @param operatorId Operator id.
     */
    function getOperatorOwner(uint32 operatorId) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator id.
     */
    function getOperatorFee(uint32 operatorId)
        external view
        returns (uint64);

    /**
     * @dev Gets active validator count.
     */
    function activeValidatorCount() external view returns (uint32);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Get validators amount per operator.
     * @param operatorId Operator public key
     */
    function validatorsPerOperatorCount(uint32 operatorId) external view returns (uint32);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/ISSVNetwork.sol";
import "./SSVETH.sol";


error LiquidStakingPool__AtleastFourOperators(uint idsLength);
error LiquidStakingPool__CantStakeZeroWei();
error LiquidStakingPool__EtherCallFailed();
error LiquidStakingPool__OperatorIdAlreadyAdded(uint32 operatorId, uint index);
error LiquidStakingPool__InputLengthsMustMatch(uint operatorsIds, uint sharesPublicKeys, uint encryptedKeys);
error LiquidStakingPool__InvalidOperatorIndex(uint operatorIdsLength, uint operatorIndex);
error LiquidStakingPool__InvalidPublicKeyLength(uint publicKeyLength);
error LiquidStakingPool__InsufficientEtherBalance(uint requiredBalance, uint currentBalance);

/**
* @title StakingPool
* @author Rohan Nero
* @notice this contract allows multiple users to activate a validator and split the key into SSV keyshares
* @dev this contract issues a staking token called SSVETH upon calling `stake()` */
contract LiquidStakingPoolV1 is Ownable, ReentrancyGuard {

    IDepositContract private immutable DepositContract;
    SSVETH private ssvETH;
    IERC20 private token;
    ISSVNetwork private network;
    uint72 private constant VALIDATOR_AMOUNT = 32 * 1e18;
    uint32[] private operatorIds;
    bytes[] private validators;
    mapping(address => uint256) private userStake;

    event UserStaked(address indexed user, uint256 indexed amount);
    event UserUnstaked(address indexed user, uint256 indexed amount);
    event PublicKeyDeposited(bytes indexed pubkey);
    event OperatorAdded(uint32 indexed operatorId, uint operatorIdsIndex);
    event OperatorRemoved(uint32 indexed operatorId);
    event KeySharesDeposited(
        bytes indexed pubkey,
        bytes[] indexed sharesPublicKeys,
        uint32[] indexed operatorIds,
        uint256 SSVamount
    );

    /**@notice sets contract addresses and operatorIds 
     * @param depositAddress the beacon chain's deposit contract
     * @param ssvNetwork the ISSVNetwork contract address (interface)
     * @param ssvToken the SSVToken contract address
     * @param _operatorIds the SSV operatorIds you've selected */
     constructor(
        address depositAddress,
        address ssvNetwork,
        address ssvToken,
        uint32[] memory _operatorIds
    ) payable {
        DepositContract = IDepositContract(depositAddress);
        SSVETH _ssvETH = new SSVETH();
        ssvETH = SSVETH(address(_ssvETH));
        token = IERC20(ssvToken);
        network = ISSVNetwork(ssvNetwork);
        if(_operatorIds.length < 4) {
            revert LiquidStakingPool__AtleastFourOperators(_operatorIds.length);
        }
        if(msg.value > 0) {
            userStake[tx.origin] += msg.value;
            ssvETH.mint(tx.origin, msg.value);
            emit UserStaked(tx.origin, msg.value);
        }
        operatorIds = _operatorIds;
    }

    /**@notice called when the contract receives ETH 
     */
    receive() external payable {
        ssvETH.mint(msg.sender, msg.value);
        userStake[msg.sender] += msg.value;
        emit UserStaked(msg.sender, msg.value);
    }    


    /** Main functions */


    /**@notice stake tokens on behalf of msg.sender
     */
    function stake() public payable nonReentrant {
        if(msg.value == 0) {
            revert LiquidStakingPool__CantStakeZeroWei();
        }
        ssvETH.mint(msg.sender, msg.value);
        userStake[msg.sender] += msg.value;
        emit UserStaked(msg.sender, msg.value);
    }

    /**@notice Unstake tokens
     * @param amount: Amount to be unstaked
     */
    function unstake(uint256 amount) public nonReentrant {
        ssvETH.burnFrom(msg.sender, amount);
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if(!sent) {
            revert LiquidStakingPool__EtherCallFailed();
        }
        userStake[msg.sender] -= amount;
        emit UserUnstaked(msg.sender, amount);
    }

    /**@notice Deposit a validator to the deposit contract
     * @dev these params together are known as the DepositData
     * @param publicKey: Public key of the validator
     * @param _withdrawal_credentials: Withdrawal public key of the validator
     * @param _signature: BLS12-381 signature of the deposit data
     * @param _deposit_data_root: The SHA-256 hash of the SSZ-encoded DepositData object
     */
    function depositValidator(
        bytes calldata publicKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        if(address(this).balance < VALIDATOR_AMOUNT) {
            revert LiquidStakingPool__InsufficientEtherBalance(VALIDATOR_AMOUNT ,address(this).balance);
        }
        if (publicKey.length != 48) {
            revert LiquidStakingPool__InvalidPublicKeyLength(publicKey.length);
        }
        DepositContract.deposit{value: VALIDATOR_AMOUNT}(
            publicKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );
        emit PublicKeyDeposited(publicKey);
    }

    /**@notice allows owner to submit validator keys and operator keys to SSVNetwork
     * @dev Deposit shares for a validator
     * @param publicKey: Public key of the validator
     * @param _operatorIds: IDs of the validator's operators
     * @param sharesPublicKeys: Public keys of the shares
     * @param encryptedKeys: Encrypted private keys
     * @param amount: Amount of tokens to be deposited
     */
    function depositShares(
        bytes calldata publicKey,
        uint32[] calldata _operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 amount
    ) external onlyOwner {
        if (publicKey.length != 48) {
            revert LiquidStakingPool__InvalidPublicKeyLength(publicKey.length);
        }
        if (_operatorIds.length < 4 ) {
            revert LiquidStakingPool__AtleastFourOperators(_operatorIds.length);
        }
        if (
            _operatorIds.length != sharesPublicKeys.length ||
            _operatorIds.length != encryptedKeys.length
            
        ) {
            revert LiquidStakingPool__InputLengthsMustMatch(_operatorIds.length, sharesPublicKeys.length, encryptedKeys.length);
        }
        token.approve(address(network), amount);
        network.registerValidator(
            publicKey,
            _operatorIds,
            sharesPublicKeys,
            encryptedKeys,
            amount
        );
        validators.push(publicKey);
        emit KeySharesDeposited(publicKey, sharesPublicKeys,_operatorIds, amount);
    }

    /**@notice allows the owner to add operators to the operatorIds array
     * @param  operatorId the operatorId assigned by SSV */
    function addOperator(uint32 operatorId) public onlyOwner {
        for(uint i; i < operatorIds.length; i++) {
            if(operatorIds[i] == operatorId) {
                revert LiquidStakingPool__OperatorIdAlreadyAdded(operatorId, i);
            }
        }
        operatorIds.push(operatorId);
        emit OperatorAdded(operatorId, operatorIds.length -1);
    }

    /**@notice allows owner to remove operators from the operatorIds array 
     * @param operatorIndex operatorIds array index of the Id to be removed */
    function removeOperator(uint32 operatorIndex) public onlyOwner {
        uint32 operatorId = operatorIds[operatorIndex];
        if(operatorIndex >= operatorIds.length) {
            revert LiquidStakingPool__InvalidOperatorIndex(operatorIds.length, operatorIndex);
        }
        if(operatorIds.length - 1 == operatorIndex) {
            operatorIds.pop;
        } else {
            operatorIds[operatorIndex] = operatorIds[operatorIds.length - 1];
            operatorIds.pop;
        }
        emit OperatorRemoved(operatorId);
    }

    /**@notice this function calls SSVNetwork's `updateValidator()`
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param _operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     * @param amount Amount of tokens to deposit.
     */
    function updateValidators(bytes calldata publicKey,
        uint32[] calldata _operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted,
        uint256 amount
    ) external onlyOwner {
        network.updateValidator(publicKey, _operatorIds, sharesPublicKeys, sharesEncrypted, amount);
    }


    /** View / Pure functions */


    /**@notice returns current address of the deposit contract 
     */
    function viewDepositContractAddress() public view returns (address depositContract) {
        depositContract = address(DepositContract);
    }
    
    /**@notice returns the current liquid staking token address
      */
    function viewSSVETHAddress() public view returns(address ssvEth) {
        ssvEth = address(ssvETH);
    }

    /**@notice returns the current SSVToken contract address 
     */
    function viewSSVTokenAddress() public view returns (address ssvToken) {
        ssvToken = address(token);
    }

    /**@notice returns the current SSVNetwork contract address
      */
    function viewSSVNetworkAddress() public view returns(address ssvNetwork) {
        ssvNetwork = address(network);
    }

    /**@notice returns the amount required to activate a validator in wei
      *@dev this is the uint72 VALIDATOR_AMOUNT variable which was initialized in the constructor 
      */
    function viewValidatorAmount() public pure returns(uint72 validatorAmount) {
        validatorAmount = VALIDATOR_AMOUNT;
    }

    /**@notice returns operator ids, check operators here https://explorer.ssv.network/
     */
    function viewOperators() public view returns (uint32[] memory operatorArray) {
        operatorArray = operatorIds;
    }

    /**@notice returns the list of validator public keys activated by this contract
      *@dev returns the Validators array
     */
    function viewValidators() public view returns (bytes[] memory validatorArray) {
        validatorArray = validators;
    }

    /**@notice returns user's staked amount
     */
    function viewUserStake(address _userAddress) public view returns (uint256 usersStake) {
        usersStake = userStake[_userAddress];
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title SSVETH
* @author Rohan Nero
* @notice this is the liquid staking pool token issued when you stake with DVTLiquidStakingPool
 */
contract SSVETH is ERC20Burnable, Ownable {

    address private immutable stakingPool;
    
    constructor() ERC20("SecretSharedValidatorEthereum", "SSVETH"){
        stakingPool = msg.sender;
    }

    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    /** @notice this returns the address  */
    function viewStakingPoolAddress() public view returns(address) {
        return stakingPool;
    }



}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './StakingPoolV1.sol';
import './LiquidStakingPoolV1.sol';

/**
* @title StakingFactoryV1
* @author Rohan Nero
* @notice this contract is used to deploy either StakingFactoryV1 or LiquidStakingPoolV1 */
contract StakingFactoryV1 {

    /**@notice creates contract addresses and operatorIds 
     * @param depositAddress the beacon chain's deposit contract
     * @param ssvNetwork the ISSVNetwork contract address (interface)
     * @param ssvToken the SSVToken contract address
     * @param _operatorIds the SSV operatorIds you've selected */
    function createStakingPool(address depositAddress, address ssvNetwork, address ssvToken, uint32[] memory _operatorIds ) public returns(address stakingPool) {
        stakingPool = address(new StakingPoolV1(depositAddress, ssvNetwork, ssvToken, _operatorIds));
    }

    /**@notice creates contract addresses and operatorIds 
     * @param depositAddress the beacon chain's deposit contract
     * @param ssvNetwork the ISSVNetwork contract address (interface)
     * @param ssvToken the SSVToken contract address
     * @param _operatorIds the SSV operatorIds you've selected */
    function createLiquidStakingPool(address depositAddress, address ssvNetwork, address ssvToken, uint32[] memory _operatorIds ) public returns(address liquidStakingPool) {
        liquidStakingPool = address(new LiquidStakingPoolV1(depositAddress, ssvNetwork, ssvToken, _operatorIds));
    }


}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/ISSVNetwork.sol";

error StakingPool__AtleastFourOperators(uint idsLength);
error StakingPool__CantStakeZeroWei();
error StakingPool__EtherCallFailed();
error StakingPool__OperatorIdAlreadyAdded(uint32 operatorId, uint index);
error StakingPool__InputLengthsMustMatch(uint operatorsIds, uint sharesPublicKeys, uint encryptedKeys);
error StakingPool__InvalidOperatorIndex(uint operatorIdsLength, uint operatorIndex);
error StakingPool__InvalidPublicKeyLength(uint publicKeyLength);
error StakingPool__NotEnoughStaked(uint amountStaked ,uint amount);
error StakingPool__InsufficientEtherBalance(uint requiredBalance, uint currentBalance);

/**
* @title StakingPool
* @author Rohan Nero
* @notice this contract allows multiple users to activate a validator and split the key into SSV keyshares
* @dev this contract does not have a liquid staking token */
contract StakingPoolV1 is Ownable, ReentrancyGuard {

    IDepositContract private immutable DepositContract;
    IERC20 private token;
    ISSVNetwork private network;
    uint72 private constant VALIDATOR_AMOUNT = 32 * 1e18;
    uint32[] private operatorIds;
    bytes[] private validators;
    mapping(address => uint256) private userStake;

    event UserStaked(address indexed user, uint256 indexed amount);
    event UserUnstaked(address indexed user, uint256 indexed amount);
    event PublicKeyDeposited(bytes indexed pubkey);
    event OperatorAdded(uint32 indexed operatorId, uint operatorIdsIndex);
    event OperatorRemoved(uint32 indexed operatorId);
    event KeySharesDeposited(
        bytes indexed pubkey,
        bytes[] indexed sharesPublicKeys,
        uint32[] indexed operatorIds,
        uint256 amount
    );

    /**@notice sets contract addresses and operatorIds 
     * @param depositAddress the beacon chain's deposit contract
     * @param ssvNetwork the ISSVNetwork contract address (interface)
     * @param ssvToken the SSVToken contract address
     * @param _operatorIds the SSV operatorIds you've selected */
    constructor(
        address depositAddress,
        address ssvNetwork,
        address ssvToken,
        uint32[] memory _operatorIds
    ) payable {
        DepositContract = IDepositContract(depositAddress);
        token = IERC20(ssvToken);
        network = ISSVNetwork(ssvNetwork);
        if(_operatorIds.length < 4) {
            revert StakingPool__AtleastFourOperators(_operatorIds.length);
        }
        if(msg.value > 0) {
            userStake[tx.origin] += msg.value;
            emit UserStaked(tx.origin, msg.value);
        }
        operatorIds = _operatorIds;
    }

    /**@notice called when the contract receives ETH 
     */
    receive() external payable {
        userStake[msg.sender] += msg.value;
        emit UserStaked(msg.sender, msg.value);
    }    


    /** Main functions */


    /**@notice stake tokens on behalf of msg.sender
     */
    function stake() public payable nonReentrant {
        if(msg.value == 0) {
            revert StakingPool__CantStakeZeroWei();
        }
        userStake[msg.sender] += msg.value;
        emit UserStaked(msg.sender, msg.value);
    }

    /**@notice Unstake tokens
     * @param amount: Amount to be unstaked
     */
    function unstake(uint256 amount) public nonReentrant {
        if(amount > userStake[msg.sender]) {
            revert StakingPool__NotEnoughStaked(userStake[msg.sender], amount);
        }
        userStake[msg.sender] -= amount;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if(!sent) {
            revert StakingPool__EtherCallFailed();
        } 
        emit UserUnstaked(msg.sender, amount);
    }

    /**@notice Deposit a validator to the deposit contract
     * @dev these params together are known as the DepositData
     * @param publicKey: Public key of the validator
     * @param _withdrawal_credentials: Withdrawal public key of the validator
     * @param _signature: BLS12-381 signature of the deposit data
     * @param _deposit_data_root: The SHA-256 hash of the SSZ-encoded DepositData object
     */
    function depositValidator(
        bytes calldata publicKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        if(address(this).balance < VALIDATOR_AMOUNT) {
            revert StakingPool__InsufficientEtherBalance(VALIDATOR_AMOUNT ,address(this).balance);
        }
        if (publicKey.length != 48) {
            revert StakingPool__InvalidPublicKeyLength(publicKey.length);
        }
        DepositContract.deposit{value: VALIDATOR_AMOUNT}(
            publicKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );
        emit PublicKeyDeposited(publicKey);
    }

    /**@notice allows owner to submit validator keys and operator keys to SSVNetwork
     * @dev Deposit shares for a validator
     * @param publicKey: Public key of the validator
     * @param _operatorIds: IDs of the validator's operators
     * @param sharesPublicKeys: Public keys of the shares
     * @param encryptedKeys: Encrypted private keys
     * @param amount: Amount of tokens to be deposited
     */
    function depositShares(
        bytes calldata publicKey,
        uint32[] calldata _operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 amount
    ) external onlyOwner {
        if (publicKey.length != 48) {
            revert StakingPool__InvalidPublicKeyLength(publicKey.length);
        }
        if (_operatorIds.length < 4 ) {
            revert StakingPool__AtleastFourOperators(_operatorIds.length);
        }
        if (
            _operatorIds.length != sharesPublicKeys.length ||
            _operatorIds.length != encryptedKeys.length
            
        ) {
            revert StakingPool__InputLengthsMustMatch(_operatorIds.length, sharesPublicKeys.length, encryptedKeys.length);
        }
        token.approve(address(network), amount);
        network.registerValidator(
            publicKey,
            _operatorIds,
            sharesPublicKeys,
            encryptedKeys,
            amount
        );
        validators.push(publicKey);
        emit KeySharesDeposited(publicKey, sharesPublicKeys,_operatorIds, amount);
    }

    /**@notice allows the owner to add operators to the operatorIds array
     * @param  operatorId the operatorId assigned by SSV */
    function addOperator(uint32 operatorId) public onlyOwner {
        for(uint i; i < operatorIds.length; i++) {
            if(operatorIds[i] == operatorId) {
                revert StakingPool__OperatorIdAlreadyAdded(operatorId, i);
            }
        }
        operatorIds.push(operatorId);
        emit OperatorAdded(operatorId, operatorIds.length -1);
    }

    /**@notice allows owner to remove operators from the operatorIds array 
     * @param operatorIndex operatorIds array index of the Id to be removed */
    function removeOperator(uint32 operatorIndex) public onlyOwner {
        uint32 operatorId = operatorIds[operatorIndex];
        if(operatorIndex >= operatorIds.length) {
            revert StakingPool__InvalidOperatorIndex(operatorIds.length, operatorIndex);
        }
        if(operatorIds.length - 1 == operatorIndex) {
            operatorIds.pop;
        } else {
            operatorIds[operatorIndex] = operatorIds[operatorIds.length - 1];
            operatorIds.pop;
        }
        emit OperatorRemoved(operatorId);
    }

    /**@notice this function calls SSVNetwork's `updateValidator()`
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param _operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     * @param amount Amount of tokens to deposit.
     */
    function updateValidators(bytes calldata publicKey,
        uint32[] calldata _operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted,
        uint256 amount
    ) external onlyOwner {
        network.updateValidator(publicKey, _operatorIds, sharesPublicKeys, sharesEncrypted, amount);
    }


    /** View / Pure functions */


    /**@notice returns current address of the deposit contract 
     */
    function viewDepositContractAddress() public view returns (address depositContract) {
        depositContract = address(DepositContract);
    }

    /**@notice returns the current SSVToken contract address 
     */
    function viewSSVTokenAddress() public view returns (address ssvToken) {
        ssvToken = address(token);
    }

    /**@notice returns the current SSVNetwork contract address
      */
    function viewSSVNetworkAddress() public view returns(address ssvNetwork) {
        ssvNetwork = address(network);
    }

    /**@notice returns the amount required to activate a validator in wei
      *@dev this is the uint72 VALIDATOR_AMOUNT variable which was initialized in the constructor 
      */
    function viewValidatorAmount() public pure returns(uint72 validatorAmount) {
        validatorAmount = VALIDATOR_AMOUNT;
    }

    /**@notice returns operator ids, check operators here https://explorer.ssv.network/
     */
    function viewOperators() public view returns (uint32[] memory operatorArray) {
        operatorArray = operatorIds;
    }

    /**@notice returns the list of validator public keys activated by this contract
      *@dev returns the Validators array
     */
    function viewValidators() public view returns (bytes[] memory validatorArray) {
        validatorArray = validators;
    }

    /**@notice returns user's staked amount
     */
    function viewUserStake(address _userAddress) public view returns (uint256 usersStake) {
        usersStake = userStake[_userAddress];
    }

}