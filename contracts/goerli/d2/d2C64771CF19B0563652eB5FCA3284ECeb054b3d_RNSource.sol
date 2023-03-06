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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/ILotterySetup.sol";
import "src/interfaces/IRNSourceController.sol";
import "src/interfaces/ITicket.sol";
import "src/interfaces/IReferralSystem.sol";

/// @dev Invalid ticket is provided. This means the selection count is not `selectionSize`,
/// or one of the numbers is not in range [1, selectionMax].
error InvalidTicket();

/// @dev Cannot execute draw if it is already in progress.
error DrawAlreadyInProgress();

/// @dev Cannot finalize draw if it is not in executing phase.
error DrawNotInProgress();

/// @dev Executing draw before it's scheduled period.
error ExecutingDrawTooEarly();

/// @dev Provided arrays of drawIds and Tickets with different length.
/// @param drawIdsLen Length of drawIds array.
/// @param ticketsLen Length of tickets array.
error DrawsAndTicketsLenMismatch(uint256 drawIdsLen, uint256 ticketsLen);

/// @dev Claim executed by someone else other than ticket owner.
/// @param ticketId Unique ticket identifier being claimed.
/// @param claimer User trying to execute claim.
error UnauthorizedClaim(uint256 ticketId, address claimer);

/// @dev Trying to claim win for a non-winning ticket or a ticket that was already claimed.
/// @param ticketId Unique ticket identifier being claimed.
error NothingToClaim(uint256 ticketId);

/// @dev The draw with @param drawId is not finished
/// @param drawId Unique identifier for draw
error DrawNotFinished(uint128 drawId);

/// @dev List of implemented rewards.
/// @param FRONTEND Reward paid to frontend operators for each ticket sold.
/// @param STAKING Reward for stakers of LotteryToken.
enum LotteryRewardType {
    FRONTEND,
    STAKING
}

/// @dev Interface that decentralized lottery implements
interface ILottery is ITicket, ILotterySetup, IRNSourceController, IReferralSystem {
    /// @dev New ticket has been purchased by `user` for `drawId`.
    /// @param currentDraw Currently active draw.
    /// @param ticketId Ticket unique identifier.
    /// @param drawId Draw for which the ticket was purchased.
    /// @param user Address of the user buying ticket.
    /// @param combination Ticket combination represented as packed uint120.
    /// @param frontend Frontend operator that sold the ticket.
    /// @param referrer Referrer address that referred ticket sale.
    event NewTicket(
        uint128 currentDraw,
        uint256 ticketId,
        uint128 drawId,
        address indexed user,
        uint120 combination,
        address indexed frontend,
        address indexed referrer
    );

    /// @dev Rewards are claimed from the lottery.
    /// @param rewardRecipient Address that received the reward.
    /// @param amount Total amount of rewards claimed.
    /// @param rewardType 0 - staking reward, 1 - frontend reward.
    event ClaimedRewards(address indexed rewardRecipient, uint256 indexed amount, LotteryRewardType indexed rewardType);

    /// @dev Winnings are claimed from the lottery for particular ticket
    /// @param user Address of the user claiming winnings.
    /// @param ticketId Ticket unique identifier.
    /// @param amount Total amount of winnings claimed.
    event ClaimedTicket(address indexed user, uint256 indexed ticketId, uint256 indexed amount);

    /// @dev Started executing draw for the drawId.
    /// @param drawId Draw that is being executed.
    event StartedExecutingDraw(uint128 indexed drawId);

    /// @dev Triggered after finishing the draw process.
    /// @param drawId Draw being finished.
    /// @param randomNumber Random number used for reconstructing ticket.
    /// @param winningTicket Winning ticket represented as packed uint120.
    event FinishedExecutingDraw(uint128 indexed drawId, uint256 indexed randomNumber, uint120 indexed winningTicket);

    /// @return rewardRecipient Staking fee recipient.
    function stakingRewardRecipient() external view returns (address rewardRecipient);

    /// @return ticketId Next ticket id to be minted after the last draw was finalized.
    function lastDrawFinalTicketId() external view returns (uint256 ticketId);

    /// @return Is executing draw in progress.
    function drawExecutionInProgress() external view returns (bool);

    /// @dev Checks amount to payout for winning ticket for particular draw.
    /// @param drawId Unique identifier of a draw we are querying.
    /// @param winTier Tier of the win (selectionSize for jackpot).
    /// @return amount Amount claimable by winning ticket holder.
    function winAmount(uint128 drawId, uint8 winTier) external view returns (uint256 amount);

    /// @dev Checks the current reward size for the particular win tier.
    /// @param winTier Tier of the win, `selectionSize` for jackpot.
    /// @return rewardSize Size of the reward for win tier.
    function currentRewardSize(uint8 winTier) external view returns (uint256 rewardSize);

    /// @param drawId Unique identifier of a draw we are querying.
    /// @return sold Number of tickets sold per draw.
    function ticketsSold(uint128 drawId) external view returns (uint256 sold);

    /// @return netProfit Current cumulative net profit calculated when the last draw was finished.
    function currentNetProfit() external view returns (int256 netProfit);

    /// @param rewardType type of the reward being checked.
    /// @return rewards Amount of rewards to be paid out.
    function unclaimedRewards(LotteryRewardType rewardType) external view returns (uint256 rewards);

    /// @return drawId Current game in progress.
    function currentDraw() external view returns (uint128 drawId);

    /// @dev Checks winning combination for particular draw.
    /// @param drawId Unique identifier of a draw we are querying.
    /// @return winningCombination Actual winning combination for a draw.
    function winningTicket(uint128 drawId) external view returns (uint120 winningCombination);

    /// @dev Buy set of tickets for the upcoming lotteries.
    /// `msg.sender` pays `ticketPrice` for each ticket and provides combination of numbers for each ticket.
    /// Reverts in case of invalid number combination in any of the tickets.
    /// Reverts in case of insufficient `rewardToken`(`tickets.length * ticketPrice`) in `msg.sender`'s account.
    /// Requires approval to spend `msg.sender`'s `rewardToken` of at least `tickets.length * ticketPrice`
    /// @param drawIds Draw identifiers user buys ticket for.
    /// @param tickets list of uint120 packed tickets. Needs to be of same length as `drawIds`.
    /// @param frontend Address of a frontend operator selling the ticket.
    /// @param referrer The address of a referrer.
    /// @return ticketIds List of minted ticket identifiers.
    function buyTickets(
        uint128[] calldata drawIds,
        uint120[] calldata tickets,
        address frontend,
        address referrer
    )
        external
        returns (uint256[] memory ticketIds);

    /// @dev Transfers all unclaimed rewards to frontend operator, or staking recipient.
    /// @param rewardType type of the reward being claimed.
    /// @return claimedAmount Amount of tokens claimed to `feeRecipient`
    function claimRewards(LotteryRewardType rewardType) external returns (uint256 claimedAmount);

    /// @dev Transfer all winnings to `msg.sender` for the winning tickets.
    /// It reverts in case of non winning ticket.
    /// Only ticket owner can claim win, if any of the tickets is not owned by `msg.sender` it will revert.
    /// @param ticketIds List of ids of the tickets being claimed.
    /// @return claimedAmount Amount of reward tokens claimed to `msg.sender`.
    function claimWinningTickets(uint256[] calldata ticketIds) external returns (uint256 claimedAmount);

    /// @dev checks claimable amount for specific ticket.
    /// @param ticketId Id of the ticket.
    /// @return claimableAmount Amount that can be claimed with this ticket.
    /// @return winTier Tier of the winning ticket (selectionSize for jackpot).
    function claimable(uint256 ticketId) external view returns (uint256 claimableAmount, uint8 winTier);

    /// @dev Starts draw process. Requests a random number from `randomNumberSource`.
    function executeDraw() external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/ITicket.sol";

/// @dev Provided reward token is zero
error RewardTokenZero();

/// @dev Provided draw cooldown period >= drawPeriod
error DrawPeriodInvalidSetup();

/// @dev Provided initial pot deadline set to be in past
error InitialPotPeriodTooShort();

/// @dev Provided ticket price is zero
error TicketPriceZero();

/// @dev Provided selection size iz zero
error SelectionSizeZero();

/// @dev Provided selection size max is too big
error SelectionSizeMaxTooBig();

/// @dev Provided selection size is too big
error SelectionSizeTooBig();

/// @dev Provided expected payout is too low or too big
error InvalidExpectedPayout();

/// @dev Invalid fixed rewards setup was provided
error InvalidFixedRewardSetup();

/// @dev Trying to finalize initial pot raise before the deadline
error FinalizingInitialPotBeforeDeadline();

/// @dev Raised insufficient funds for the initial pot
/// @param potSize size of the pot raised
error RaisedInsufficientFunds(uint256 potSize);

/// @dev Jackpot is not yet initialized, it means we are still in initial pot raise timeframe
error JackpotNotInitialized();

/// @dev Trying to initialize already initialized jackpot
error JackpotAlreadyInitialized();

/// @dev Cannot buy tickets for this draw anymore as it is in cooldown mode
/// @param drawId Draw identifier that is in cooldown mode
error TicketRegistrationClosed(uint128 drawId);

/// @dev Lottery draw schedule parameters
struct LotteryDrawSchedule {
    /// @dev First draw is scheduled to take place at this timestamp
    uint256 firstDrawScheduledAt;
    /// @dev Period for running lottery
    uint256 drawPeriod;
    /// @dev Cooldown period when users cannot register tickets for draw anymore
    uint256 drawCoolDownPeriod;
}

/// @dev Parameters used to setup a new lottery
struct LotterySetupParams {
    /// @dev Token to be used as reward token for the lottery
    IERC20 token;
    /// @dev Parameters of the draw schedule for the lottery
    LotteryDrawSchedule drawSchedule;
    /// @dev Price to pay for playing single game (including fee)
    uint256 ticketPrice;
    /// @dev Count of numbers user picks for the ticket
    uint8 selectionSize;
    /// @dev Max number user can pick
    uint8 selectionMax;
    /// @dev Expected payout for one ticket, expressed in `rewardToken`
    uint256 expectedPayout;
    /// @dev Array of fixed rewards per each non jackpot win
    uint256[] fixedRewards;
}

interface ILotterySetup {
    /// @dev Triggered when new Lottery is deployed
    /// token Token to be used as reward token for the lottery
    /// drawSchedule Parameters of the draw schedule for the lottery
    /// ticketPrice Price to pay for playing single game (including fee)
    /// selectionSize Count of numbers user picks for the ticket
    /// selectionMax Max number user can pick
    /// expectedPayout Expected payout for one ticket, expressed in `rewardToken`
    /// fixedRewards List of fixed non jackpot rewards
    event LotteryDeployed(
        IERC20 token,
        uint256 indexed firstDrawScheduledAt,
        uint256 drawPeriod,
        uint256 drawCoolDownPeriod,
        uint256 ticketPrice,
        uint8 indexed selectionSize,
        uint8 indexed selectionMax,
        uint256 expectedPayout,
        uint256[] fixedRewards
    );

    /// @dev Triggered when the initial pot raise period is over
    /// @param amountRaised Total amount raised during this period
    event InitialPotPeriodFinalized(uint256 indexed amountRaised);

    /// @return minPot Minimum amount to be raised in initial funding period
    function minInitialPot() external view returns (uint256 minPot);

    /// @return bound Maximum base jackpot
    function jackpotBound() external view returns (uint256 bound);

    /// @dev Token to be used as reward token for the lottery
    /// It is used for both rewards and paying for tickets
    /// @return token Reward token address
    function rewardToken() external view returns (IERC20 token);

    /// @return token Native token of the lottery. Used for staking and for referral rewards.
    function nativeToken() external view returns (IERC20 token);

    /// @dev Price to pay for playing single game of lottery
    /// User pays it when registering the ticket for the game
    /// It is expressed in `rewardToken`
    /// @return price Price per ticket
    function ticketPrice() external view returns (uint256 price);

    /// @param winTier Tier of the win (selectionSize for jackpot)
    /// @return amount Fixed reward for particular win tier
    function fixedReward(uint8 winTier) external view returns (uint256 amount);

    /// @return potSize The size of the pot after initial pot period is over
    function initialPot() external view returns (uint256 potSize);

    /// @dev When registering ticket, user selects total of `selectionSize` numbers
    /// @return size Count of numbers user picks for the ticket
    function selectionSize() external view returns (uint8 size);

    /// @dev When registering ticket, user selects total of `selectionSize` numbers
    /// These numbers must be in range [1, `selectionMax`]
    /// @return max Max number user can pick
    function selectionMax() external view returns (uint8 max);

    /// @return payout Expected payout for one ticket in reward token
    function expectedPayout() external view returns (uint256 payout);

    /// @return period Period between 2 draws
    function drawPeriod() external view returns (uint256 period);

    /// @return topUpEndsAt Timestamp when initial pot raising is finished
    function initialPotDeadline() external view returns (uint256 topUpEndsAt);

    /// @return period Cooldown period, just before draw is scheduled, at this time tickets cannot be registered
    function drawCoolDownPeriod() external view returns (uint256 period);

    /// @dev Checks for the scheduled time for particular draw
    /// @param drawId Draw identifier we check schedule for
    /// @return time Timestamp after which draw can be executed
    function drawScheduledAt(uint128 drawId) external view returns (uint256 time);

    /// @dev Checks for the last time at which tickets can be bought
    /// @param drawId Draw identifier we check deadline for
    /// @return time Timestamp after which tickets can not be bought
    function ticketRegistrationDeadline(uint128 drawId) external view returns (uint256 time);

    /// @dev Finalize the initial pot raising and initialize jackpot
    function finalizeInitialPotRaise() external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Caller is not allowed to mint tokens.
error UnauthorizedMint();

/// @dev Interface for the Lottery token.
interface ILotteryToken is IERC20 {
    /// @dev Initial supply minted at the token deployment.
    function INITIAL_SUPPLY() external view returns (uint256 initialSupply);

    /// @return _owner The owner of the contract
    function owner() external view returns (address _owner);

    /// @dev Mints number of tokens for particular draw and assigns them to `account`, increasing the total supply.
    /// Mint is done for the `nextDrawToBeMintedFor`
    /// @param account The recipient of tokens
    /// @param amount Number of tokens to be minted
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

interface IRNSource {
    /// @dev Non existent request, this should never happen as it means the underlying source
    /// reported number for a non-existent request ID
    /// @param requestId id of the request that is being checked
    error RequestNotFound(uint256 requestId);

    /// @dev The generated request ID was used before
    /// @param requestId The duplicate generated request ID
    error RequestAlreadyFulfilled(uint256 requestId);

    /// @dev Consumer is not allowed to request random numbers
    /// @param consumer Address of consumer that tried requesting random number
    error UnauthorizedConsumer(address consumer);

    /// @dev The generated request ID was used before
    /// @param requestId The duplicate generated request ID
    error requestIdAlreadyExists(uint256 requestId);

    /// @dev Emitted when a random number is requested
    /// @param consumer Consumer requested random number
    /// @param requestId identifier of the request
    event RequestedRandomNumber(address indexed consumer, uint256 indexed requestId);

    /// @dev Request is fulfilled
    /// @param requestId identifier of the request being fulfilled
    /// @param randomNumber random number generated
    event RequestFulfilled(uint256 indexed requestId, uint256 indexed randomNumber);

    enum RequestStatus {
        None,
        Pending,
        Fulfilled
    }

    struct RandomnessRequest {
        /// @dev specifies the request status
        RequestStatus status;
        /// @dev Random number generated for particular request
        uint256 randomNumber;
    }

    /// @dev Requests a new random number from the source
    function requestRandomNumber() external;
}

interface IRNSourceConsumer {
    /// @dev After requesting random number from IRNSource
    /// this method will be called by IRNSource to deliver generated number
    /// @param randomNumber Generated random number
    function onRandomNumberFulfilled(uint256 randomNumber) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "src/interfaces/IRNSource.sol";

/// @dev Provided Random number source is zero
error RNSourceZeroAddress();

/// @dev Current random number request is still active.
error CurrentRequestStillActive();

/// @dev Thrown when trying to invoke `retry` while there is no pending request.
error CannotRetrySuccessfulRequest();

/// @dev Thrown when trying to request a random number while a pending request exists.
error PreviousRequestNotFulfilled();

/// @dev Thrown when trying to deploy a contract with a `maxFailedAttempts` param that is too big.
error MaxFailedAttemptsTooBig();

/// @dev Thrown when trying to deploy a contract with a `maxRequestsDelay` param that is too big.
error MaxRequestDelayTooBig();

/// @dev Thrown when trying to swap randomness source before the current source failed `maxFailedAttempts` times.
error NotEnoughFailedAttempts();

/// @dev Thrown when trying to initialize a randomness source after one was already initialized.
error AlreadyInitialized();

/// @dev Random number fulfillment is unauthorized.
error RandomNumberFulfillmentUnauthorized();

/// @dev A contract that controls the list of random number sources and dispatches random number requests to them.
interface IRNSourceController is IRNSourceConsumer {
    /// @dev Emitted on request retry.
    /// @param failedSource The address of the failed source
    /// @param numberOfFailedAttempts A total number of failed attempts for @param failedSource
    event Retry(IRNSource indexed failedSource, uint256 indexed numberOfFailedAttempts);

    /// @dev Emitted when a new randomness source is set.
    /// @param source The randomness source which was set
    event SourceSet(IRNSource indexed source);

    /// @dev Emitted on a successful randomness request.
    /// @param source The source from which randomness was successfully requested
    event SuccessfulRNRequest(IRNSource indexed source);

    /// @dev Emitted on a failed randomness request.
    /// @param source The source from which randomness was unsuccessfully requested
    /// @param reason The reason why the randomness request, directly propagated from the randomness source
    event FailedRNRequest(IRNSource indexed source, bytes indexed reason);

    /// @dev The current randomness source.
    function source() external view returns (IRNSource source);

    /// @dev Retrieves the number of failed sequential request attempts for the current source.
    function failedSequentialAttempts() external view returns (uint256 numberOfAttempts);

    /// @dev Retrieves the timestamp at which the current source reached `maxFailedAttempts` number of retries.
    function maxFailedAttemptsReachedAt() external view returns (uint256 numberOfAttempts);

    /// @return numberOfAttempts The number of the maximum failed attempts after the source will be removed
    function maxFailedAttempts() external view returns (uint256 numberOfAttempts);

    /// @return timestamp A timestamp for the last data request
    function lastRequestTimestamp() external view returns (uint256 timestamp);

    /// @return isFulfilled Get is last request fulfilled
    function lastRequestFulfilled() external view returns (bool isFulfilled);

    /// @return delay The maximum delay between random number request and its fulfillment
    function maxRequestDelay() external view returns (uint256 delay);

    /// @dev Called by the current random number source to deliver a generated random number.
    /// @param randomNumber A random number generated by the current random number source
    function onRandomNumberFulfilled(uint256 randomNumber) external;

    /// @dev Initializes the controller's underlying randomness source.
    function initSource(IRNSource rnSource) external;

    /// @dev Retries a randomness request. Can only be called when at least `maxRequestDelay` amount of time
    /// passed since `lastRequestTimestamp`.
    function retry() external;

    /// @dev Swaps the controller's underlying randomness source. Can only be called by the owner and after
    /// at least `maxFailedAttempts` retries were invoked.
    /// @param newSource A new random number source to be added to the list of sources
    function swapSource(IRNSource newSource) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/ILotteryToken.sol";

/// @dev Referrer rewards setup is invalid
error ReferrerRewardsInvalid();

interface IReferralSystem {
    /// @dev Data about number of tickets user did not claim rewards for
    struct UnclaimedTicketsData {
        /// @dev Number of tickets sold as referrer for which rewards are unclaimed
        uint128 referrerTicketCount;
        /// @dev Number of tickets user has bought for which rewards are unclaimed
        uint128 playerTicketCount;
    }

    /// @dev Referrer with address @param referrer claimed amount @param claimedAmount for a draw @param drawId
    /// @param drawId Unique identifier for draw
    /// @param user The address of the referrer or player
    /// @param claimedAmount Claimed reward in the lotteryToken
    event ClaimedReferralReward(uint128 indexed drawId, address indexed user, uint256 indexed claimedAmount);

    /// @dev Reward amounts for referrers and players are calculated for draw with @param drawId
    /// @param drawId Unique identifier for draw
    /// @param referrerRewardForDraw Reward amount for referrers for draw with @param drawId
    /// @param playerRewardForDraw Reward amount for players for draw with @param drawId
    event CalculatedRewardsForDraw(
        uint128 indexed drawId, uint256 indexed referrerRewardForDraw, uint256 indexed playerRewardForDraw
    );

    /// @dev The setup for the rewards for referrers.
    /// @param drawId Unique identifier of the draw rewards are queried for.
    /// @return reffererRewards Total reward amount going to referrers.
    function rewardsToReferrersPerDraw(uint256 drawId) external view returns (uint256 reffererRewards);

    /// @dev Retrieves total reward for players for first draw.
    function playerRewardFirstDraw() external view returns (uint256);

    /// @dev Retrieves decrease size for the each draw after the first one.
    /// Reward for players is calculated as `playerRewardFirstDraw - drawId * playerRewardDecreasePerDraw`.
    function playerRewardDecreasePerDraw() external view returns (uint256);

    function unclaimedTickets(
        uint128 drawId,
        address user
    )
        external
        view
        returns (uint128 referrerTicketCount, uint128 playerTicketCount);

    /// @param drawId Unique identifier for draw
    /// @return totalNumberOfTickets The total number of tickets that are added for referrers for @param drawId
    function totalTicketsForReferrersPerDraw(uint128 drawId) external view returns (uint256 totalNumberOfTickets);

    /// @dev Referrer's rewards per draw for one ticket
    /// @param drawId Unique identifier for draw
    function referrerRewardPerDrawForOneTicket(uint128 drawId) external view returns (uint256 rewardsPerDraw);

    /// @dev Player's rewards per draw for one ticket
    /// @param drawId Unique identifier for draw
    function playerRewardsPerDrawForOneTicket(uint128 drawId) external view returns (uint256 rewardsPerDraw);

    /// @dev Claims both player and referrer reward if applicable
    /// @param drawIds List of draws reward is claimed for
    /// @return claimedReward Total amount claimed containing both player and referrer reward
    function claimReferralReward(uint128[] memory drawIds) external returns (uint256 claimedReward);

    /// @param drawId Unique identifier for draw
    /// @return minimumEligibleReferrals Calculate the minimum eligible referrals that are needed for the referrer to be
    /// rewarded
    function minimumEligibleReferrals(uint128 drawId) external view returns (uint256 minimumEligibleReferrals);
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Interface representing Ticket NTF.
/// Ticket NFT represents ownership of the lottery ticket.
interface ITicket is IERC721 {
    /// @dev Information about the ticket.
    struct TicketInfo {
        /// @dev Unique identifier of the draw ticket was bought for.
        uint128 drawId;
        /// @dev Ticket combination that is packed as uint120.
        uint120 combination;
        /// @dev If ticket is already claimed, in case of winning ticket.
        bool claimed;
    }

    /// @dev Identifier that will be assigned to the next minted token
    /// @return nextId Next identifier to be assigned
    function nextTicketId() external view returns (uint256 nextId);

    /// @dev Retrieves information about a ticket given a `ticketId`.
    /// @param ticketId Unique identifier of the ticket.
    /// @return drawId Unique identifier of the draw ticket was bought for.
    /// @return combination Ticket combination that is packed as uint120.
    /// @return claimed If ticket is already claimed, in case of winning ticket.
    function ticketsInfo(uint256 ticketId) external view returns (uint128 drawId, uint120 combination, bool claimed);
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/IRNSource.sol";
import "src/interfaces/ILottery.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RNSource is IRNSource {
    error MockReverted();

    address internal authorizedConsumer;
    RequestRandomNumberMockMode public mode;

    enum RequestRandomNumberMockMode {
        Success,
        Revert,
        Require
    }

    constructor(address _authorizedConsumer) {
        authorizedConsumer = _authorizedConsumer;
    }

    function setMockMode(RequestRandomNumberMockMode _mode) external {
        mode = _mode;
    }

    function requestRandomNumber() external view {
        if (mode == RequestRandomNumberMockMode.Revert) {
            revert MockReverted();
        } else if (mode == RequestRandomNumberMockMode.Require) {
            require(false, "mockFailed");
        }
    }

    function fulfillRandomNumber(uint256 randomNumber) external {
        IRNSourceConsumer(authorizedConsumer).onRandomNumberFulfilled(randomNumber);
    }
}