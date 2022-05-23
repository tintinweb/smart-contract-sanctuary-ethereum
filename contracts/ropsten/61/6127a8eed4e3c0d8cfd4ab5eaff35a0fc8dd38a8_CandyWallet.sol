/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// The following code is from flattening this file: CandyWallet.sol
// : UNLICENSED
pragma solidity ^0.8.0;

// The following code is from flattening this import statement in: CandyWallet.sol
// import '@openzeppelin/contracts/access/Ownable.sol';
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/access/Ownable.sol
// : MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

// The following code is from flattening this import statement in: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/access/Ownable.sol
// import "../utils/Context.sol";
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/utils/Context.sol
// : MIT
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


// The following code is from flattening this import statement in: CandyWallet.sol
// import "./interfaces/iCandyWallet.sol";
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/contracts/interfaces/iCandyWallet.sol
// : UNLICENSED
pragma solidity ^0.8.0;

interface iCandyWallet {
	event SignedTransfer(address indexed to, uint256 amount, string uuid);
	function setTokenAddress(address token_) external;
	function getStringToSign(address destination, uint value, string memory uuid, uint256 createdAt, uint256 expiresAt) external view returns (bytes32);
	function getLevel(address signer) external view returns(uint8);
	function getRequiredLevel(uint256 amount) external view returns(uint8);
	function verifySignatures(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, bytes32 signedString) external returns(uint8[] memory);
	function withdrawTokens(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, address destination, uint value, string memory uuid, uint createdAt, uint expiresAt) external;
	function emergencyStop() external;
	function restart() external;
	function addSignature(address signer, uint8 level) external;
	function removeSignature(address signer, uint8 level) external;
	function adminWithdraw(address destination, uint value) external;
}
// The following code is from flattening this import statement in: CandyWallet.sol
// import "./SugarKingdomToken.sol";
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/contracts/SugarKingdomToken.sol
// : UNLICENSED
pragma solidity ^0.8.0;

// The following code is from flattening this import statement in: /Users/owenraman/Documents/SFWorkspace/CandyWallet/contracts/SugarKingdomToken.sol
// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol
// : MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

// The following code is from flattening this import statement in: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol
// import "./IERC20.sol";
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol
// : MIT
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

// The following code is from flattening this import statement in: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol
// import "./extensions/IERC20Metadata.sol";
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
// : MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

// Skipping this already resolved import statement found in /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol 
// import "../IERC20.sol";

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

// Skipping this already resolved import statement found in /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol 
// import "../../utils/Context.sol";

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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

// The following code is from flattening this import statement in: /Users/owenraman/Documents/SFWorkspace/CandyWallet/contracts/SugarKingdomToken.sol
// import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol
// : MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

// Skipping this already resolved import statement found in /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol 
// import "../ERC20.sol";
// Skipping this already resolved import statement found in /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol 
// import "../../../utils/Context.sol";

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

// Skipping this already resolved import statement found in /Users/owenraman/Documents/SFWorkspace/CandyWallet/contracts/SugarKingdomToken.sol 
// import '@openzeppelin/contracts/access/Ownable.sol';
// The following code is from flattening this import statement in: /Users/owenraman/Documents/SFWorkspace/CandyWallet/contracts/SugarKingdomToken.sol
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";  
// The following code is from flattening this file: /Users/owenraman/Documents/SFWorkspace/CandyWallet/node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol
// : MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


interface ILiquidityRestrictor {
    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message);
}

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);
}

contract SugarKingdomToken is ERC20, Ownable, ERC20Burnable, ReentrancyGuard {
    mapping(address => uint256) private _balances;
    mapping(uint8 => uint256[]) private _txnFees;
    mapping(address => bool) private _pools;
    mapping(address => bool) private _whitelisted;
    address public _taxAccount;
    uint256 public _maxTotalTax;

    uint256 private _totalSupply;

    IAntisnipe public antisnipe = IAntisnipe(address(0));
    ILiquidityRestrictor public liquidityRestrictor =
        ILiquidityRestrictor(0xeD1261C063563Ff916d7b1689Ac7Ef68177867F2);

    bool public antisnipeEnabled = true;
    bool public liquidityRestrictionEnabled = true;

    event AntisnipeDisabled(uint256 timestamp, address user);
    event LiquidityRestrictionDisabled(uint256 timestamp, address user);
    event AntisnipeAddressChanged(address addr);
    event LiquidityRestrictionAddressChanged(address addr);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initSupply,
        address taxAccount,
        uint256 maxTax
    ) ERC20(name_, symbol_) {
        initFees();
        require(taxAccount != address(0), "taxAccount_ can't be the zero address");
        _taxAccount = taxAccount;
        _whitelisted[msg.sender] = true;
        _mint(msg.sender, initSupply);
        _maxTotalTax = maxTax;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelisted[_address];
    }

    function addWhitelisted(address whitelisted) public onlyOwner {
        _whitelisted[whitelisted] = true;
    }

    function removeWhitelisted(address whitelisted) public onlyOwner {
        _whitelisted[whitelisted] = false;
    }

    function isPool(address _address) public view returns (bool) {
        return _pools[_address];
    }

    function addPool(address pool) public onlyOwner {
        _pools[pool] = true;
    }

    function removePool(address pool) public onlyOwner {
        _pools[pool] = false;
    }

    function setTaxAccount(address taxAccount_) public onlyOwner {
        require(taxAccount_ != address(0), "taxAccount_ can't be the zero address");
        _taxAccount = taxAccount_;
    }

    function initFees() internal {
        _txnFees[0] = [0, 0];
        _txnFees[1] = [0, 0];
        _txnFees[2] = [0, 0];
    }

    function changeFees(
        uint8 _type,
        uint256 burn,
        uint256 fee
    ) public onlyOwner {
        require((burn + fee) <= _maxTotalTax);
        _txnFees[_type] = [burn, fee];
    }

    function getFees(uint8 _type) public view returns (uint256, uint256) {
        return (_txnFees[_type][0], _txnFees[_type][1]);
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), 'ERC20: mint to the zero address');

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
    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /** @dev Calculates the fee/burn according to the amount and participants on a transfer.
      * @param sender the acount that originates the transfer.
      * @param recipient the destination of the the transfer.
      * @param amount the amount of the the transfer.
      * @return burntokens the amount of tokens to be burned
      * @return taxtokens the amount of tokens to be sent to de taxAccount
      * @return left the amount of tokens that will reach the destination account
      * @notice burnTokens + taxTokens + left will always equal the amount in.
      */
    function calculateFees(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 left = 0;
        uint256 burnTokens = 0;
        uint256 taxTokens = 0;
        uint256 burn = 0;
        uint256 tax = 0;

        if (_whitelisted[sender] || _whitelisted[recipient]) {
            left = amount;
        } else {
            if (_pools[sender]) {
                (burn, tax) = getFees(0);
            } else if (_pools[recipient]) {
                (burn, tax) = getFees(1);
            } else {
                (burn, tax) = getFees(2);
            }
            burnTokens = (amount * burn) / 100 / 10**18;
            taxTokens = (amount * tax) / 100 / 10**18;
            left = amount - burnTokens - taxTokens;
        }
        return (burnTokens, taxTokens, left);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override nonReentrant(){
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
        (uint256 burnTokens, uint256 taxTokens, uint256 left) = calculateFees(
            sender,
            recipient,
            amount
        );

        unchecked {
            _balances[sender] = senderBalance - (left + taxTokens);
        }
        _balances[recipient] += left;
        _balances[_taxAccount] += taxTokens;

        emit Transfer(sender, recipient, left);
        if (taxTokens > 0) emit Transfer(sender, _taxAccount, taxTokens);
        if (burnTokens > 0) _burn(sender, burnTokens);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0) || to == address(0)) return;
        if (liquidityRestrictionEnabled && address(liquidityRestrictor) != address(0)) {
            (bool allow, string memory message) = liquidityRestrictor
                .assureLiquidityRestrictions(from, to);
            require(allow, message);
        }

        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(antisnipe.assureCanTransfer(msg.sender, from, to, amount));
        }
    }

    function setAntisnipeDisable() external onlyOwner {
        require(antisnipeEnabled);
        antisnipeEnabled = false;
        emit AntisnipeDisabled(block.timestamp, msg.sender);
    }

    function setLiquidityRestrictorDisable() external onlyOwner {
        require(liquidityRestrictionEnabled);
        liquidityRestrictionEnabled = false;
        emit LiquidityRestrictionDisabled(block.timestamp, msg.sender);
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
        emit AntisnipeAddressChanged(addr);
    }

    function setLiquidityRestrictionAddress(address addr) external onlyOwner {
        liquidityRestrictor = ILiquidityRestrictor(addr);
        emit LiquidityRestrictionAddressChanged(addr);
    }
}
//import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * The contractName contract does this and that...
 */
contract CandyWallet is iCandyWallet{
	SugarKingdomToken public token;

	mapping(string => bool) private _uuid;
	mapping(uint8 => mapping(address => bool)) private _signers;
	uint8[] private _req_signatures;
	uint256[] private _req_amounts;
	uint256[] private _locktimes;
	uint8 private _maxLevel;
	bool private _stopped;
	bytes32 _domainSeparator;
	modifier notStopped() { 
		require (!_stopped);
		_;
	}
	bool private initialized;


	modifier requiredLevel(uint8 level){
		bool accepted = msg.sender == owner();
		for(uint8 i= level+1; i<= _maxLevel; i++){
			accepted = accepted || _signers[i][msg.sender];
		}
		require(accepted);
		_;
	}

	modifier onlySigner(){
		bool accepted = msg.sender == owner();
		for(uint8 i= 0; i<= _maxLevel; i++){
			accepted = accepted || _signers[i][msg.sender];
		}
		require(accepted);
		_;

	}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
	function initialize (address token_, address[] memory signers_, uint8[] memory levels, uint8[] memory req_signatures_, uint256[] memory req_amounts_, uint256[] memory lock_times_) public{
		require(!initialized, "Contract instance has already been initialized");
        initialized = true;
		token = SugarKingdomToken(token_);
		require(signers_.length == levels.length, "Incompatible number of levels and signatures");
		uint8 maxlevel = 0;
		for(uint8 i = 0; i<signers_.length; i++){
			_signers[levels[i]][signers_[i]] = true;
			if(levels[i]>maxlevel) maxlevel = levels[i];
		}
		_maxLevel = maxlevel;
		require((req_signatures_.length == (maxlevel+1)), "Number of rquired signatures incomtable with maximum level established");
		require((req_amounts_.length == (maxlevel+1)), "Number of rquired amounts incomtable with maximum level established");
		require((lock_times_.length == (maxlevel+1)), "Number of locktimes incomtable with maximum level established");
		_req_signatures = req_signatures_;
		_req_amounts = req_amounts_;
		_locktimes = lock_times_;
		_domainSeparator = keccak256(abi.encode("CandyWallet", block.chainid));
		_stopped = false;

	}
	function owner() public view virtual returns (address) {
		return token.owner();
	}
	function setTokenAddress(address token_) public override onlyOwner{
		token = SugarKingdomToken(token_);
	}
	function getStringToSign(address destination, uint value, string memory uuid, uint256 createdAt, uint256 expiresAt) public view override returns (bytes32){
		return keccak256(abi.encode(_domainSeparator,destination, value, uuid, createdAt, expiresAt));
	}
	function getLevel(address signer) public view override returns(uint8){
		for(uint8 i = _maxLevel+1; i >0; i--){
			if(_signers[i-1][signer]) return i-1;
		}
		require(false, "Address not a Signer");

	}
	function verifySignatures(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, bytes32 signedString) public override returns(uint8[] memory){
		require(sigR.length == sigS.length && sigR.length == sigV.length);
		uint8[] memory result = new uint8[](_maxLevel+1);
		for(uint j= 0; j< _maxLevel+1; j++) result[j] = 0;
	    address lastAdd = address(0);
	    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedString));
		for (uint i = 0; i < sigV.length; i++) {
	      address recovered = ecrecover(messageDigest, sigV[i], sigR[i], sigS[i]);

	      require(recovered > lastAdd, "addresses not in order or repeated");
	      result[getLevel(recovered)]++;
	    }
	    return result;

	}
	function getRequiredLevel(uint256 amount) public view override returns(uint8){
		for(uint8 i = _maxLevel+1; i >0; i--){
			if(_req_amounts[i-1]<amount) return i-1;
		}
		require(false, "transaction under minimum threshold");
	}
	function withdrawTokens(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, address destination, uint value, string memory uuid, uint createdAt, uint expiresAt) external override notStopped{
		bytes32 signedString = getStringToSign(destination, value, uuid, createdAt, expiresAt);
		uint8[] memory levels = verifySignatures(sigV, sigR, sigS, signedString);
		uint8 tx_requiredLevel = getRequiredLevel(value);
		require(!_uuid[uuid], "uuid repeated");
		_uuid[uuid] = true;
		require(_locktimes[tx_requiredLevel] + createdAt < block.timestamp, "transaction time locked");
		require(expiresAt > block.timestamp, "transaction expired");
		for(uint8 i = tx_requiredLevel+1; i >0; --i){
			require(levels[i-1]>= _req_signatures[i-1], "not enough signatures");
		}
		token.transfer(destination, value);
		emit SignedTransfer(destination,  value,  uuid);


	}
	function emergencyStop() public override onlySigner{
		_stopped = true;		
	}
	function restart() public override onlyOwner{
		_stopped = false;
	}
	function addSignature(address signer, uint8 level) external override requiredLevel(level){
		_signers[level][signer] = true;
	}

	function removeSignature(address signer, uint8 level) external override requiredLevel(level){
		_signers[level][signer] = false;
	}
	function set_level_limit(uint8 level, uint256 limit) external requiredLevel(level){
		_req_amounts[level] = limit;
	}
	function set_level_locktime(uint8 level, uint256 seconds_) external requiredLevel(level){
		_locktimes[level] = seconds_;
	}
	function adminWithdraw(address destination, uint value) external override onlyOwner{
		token.transfer(destination, value);
	}
	function executiveWithdraw(uint value) external requiredLevel(0){
		token.transfer(owner(), value);
	}
	function isSigner(address signer, uint8 level) external view returns(bool){
		return _signers[level][signer];
	}
	function getToken() external view returns(address){
		return address(token);
	}
	function getLimit(uint8 level) external view returns(uint256){
		return _req_amounts[level];
	}
	function getLocktime(uint8 level) external view returns(uint256){
		return _locktimes[level];
	}
	function getRequiredSignatures(uint8 level) external view returns(uint256){
		return _req_signatures[level];
	}
	function isStopped() external view returns(bool ){
		return _stopped;
	}
}