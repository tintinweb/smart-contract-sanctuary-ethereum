/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
}

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
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/
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
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/
    ) internal virtual {}
}

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

/**
 * @title IVaultToken
 * 
 * @dev An ERC20-compliant token which is tied to a specific Vault, and can be minted from that vault 
 * in exchange for a specified base token, or can be exchanged at that Vault for the specified base 
 * token. 
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
interface IVaultToken  {
    
    /**
     * Returns the address of the Vault instance that is associated with this Vault Token. Can be a zero address.
     * 
     * @return The address of the associated Vault, if any
     */
    function vaultAddress() external view returns (address); 
    
    /**
     * Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Creates tokens out of thin air. Authorized address may mint to any user. 
     * 
     * @param to Address to which to give the newly minted value.
     * @param amount The number of units of the token to mint. 
     */
    function mint(address to, uint256 amount) external;
    
    /**
     * Destroys `amount` tokens from the sender's account, reducing the total supply.
     *
     * @param amount The amount to burn. 
     */
    function burn(uint256 amount) external;
    
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address addr) external view returns (uint256); 
    
    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 amount) external returns (bool); 
    
    /**
     * Triggers stopped state, rendering many functions uncallable. 
     */
    function pause() external;
    
    /**
     * Returns to the normal state after having been paused.
     */
    function unpause() external;
    
    /**
     * This is just between the Vault and the Vault Token. It's private. Like just between them two. 
     * 
     * @param from The actual owner (not spender) of the tokens being transferred 
     * @param to The recipient of the transfer 
     * @param amount The amount to transfer
     */
    function transferFromInternal(address from, address to, uint256 amount) external returns (bool); 
}

/**
 * @title IVault 
 * 
 * An abstract representation of the Vault from the perspective of the Vault's associated VaultToken contract. 
 * 
 * The VaultToken does not need most of the Vault's methods and properties; only a small subset. The ones 
 * exposed here are the ones needed by the VaultToken. 
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
interface IVault {
    
    /**
     * Returns the address of the VaultToken instance that is associated with this Vault. 
     * 
     * @return The address as IVaultToken 
     */
    function vaultToken() external view returns (IVaultToken); 
    
    /**
     * Returns the address of the ISecurityManager instance that is associated with this Vault. 
     */
    function securityManager() external view returns (ISecurityManager);
    
    /**
     * Assumes that Vault Token has already been transferred to the Vault, and in return transfers
     * the appropriate amount of Base Token back to the sender, according to current exchange rate.
     * 
     * @param vaultTokenAmount The amount of Vault Token transferred to the Vault by `sender`. 
     * @param sender The sender of the Vault Token, who will be the recipient of Base Token from the Vault. 
     */
    function withdrawDirect(uint256 vaultTokenAmount, address sender) external;
    
    /**
     * This can only be called by an authorized user as part of the sweep-into-vault system (implemented 
     * off-chain) that allows for automatic zap-in of different currencies, and direct deposit. It essentially 
     * is a deposit by the vault sweep-in, on behalf of the `forAddress` user. 
     * 
     * @param baseTokenAmount The quantity of the base token to deposit. 
     * @param forAddress The address that will receive the VaultToken in return for the deposit. 
     */
    function depositFor(uint256 baseTokenAmount, address forAddress) external;
}

/**
 * @title ISecurityManager 
 * 
 * Interface for a contract's associated { SecurityManager } contract, from the point of view of the security-managed 
 * contract (only a small subset of the SecurityManager's methods are needed). 
 * 
 * See also { SecurityManager }
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
interface ISecurityManager  {
    
    /**
     * Returns `true` if `account` has been granted `role`.
     * 
     * @param role The role to query. 
     * @param account Does this account have the specified role?
     */
    function hasRole(bytes32 role, address account) external returns (bool); 
}

/**
 * @title ManagedSecurity 
 * 
 * This is an abstract base class for contracts whose security is managed by { SecurityManager }. It exposes 
 * the modifier which calls back to the associated { SecurityManager } contract. 
 * 
 * See also { SecurityManager }
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
abstract contract ManagedSecurity is Context { 
    //TODO: (MED) the use of Context here instead of ContextUpgradeable is questionable; consider making a separate ManagedSecurityUpgradeable
    ISecurityManager public securityManager; 
    
    //security roles 
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GENERAL_MANAGER_ROLE = keccak256("GENERAL_MANAGER_ROLE");
    bytes32 public constant LIFECYCLE_MANAGER_ROLE = keccak256("LIFECYCLE_MANAGER_ROLE");
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
    bytes32 public constant DEPOSIT_MANAGER_ROLE = keccak256("DEPOSIT_MANAGER_ROLE");
    
    //thrown when the onlyRole modifier reverts 
    error UnauthorizedAccess(bytes32 roleId, address addr); 
    
    //thrown if zero-address argument passed for securityManager
    error ZeroAddressArgument(); 
    
    //Restricts function calls to callers that have a specified security role only 
    modifier onlyRole(bytes32 role) {
        if (!securityManager.hasRole(role, _msgSender())) {
            revert UnauthorizedAccess(role, _msgSender());
        }
        _;
    }
    
    /**
     * Allows an authorized caller to set the securityManager address. 
     * 
     * Reverts: 
     * - {UnauthorizedAccess}: if caller is not authorized 
     * - {ZeroAddressArgument}: if the address passed is 0x0
     * - 'Address: low-level delegate call failed' (if `_securityManager` is not legit)
     * 
     * @param _securityManager Address of an ISecurityManager. 
     */
    function setSecurityManager(ISecurityManager _securityManager) external onlyRole(ADMIN_ROLE) {
        _setSecurityManager(_securityManager); 
    }
    
    /**
     * This call helps to check that a given address is a legitimate SecurityManager contract, by 
     * attempting to call one of its read-only methods. If it fails, this function will revert. 
     * 
     * @param _securityManager The address to check & verify 
     */
    function _setSecurityManager(ISecurityManager _securityManager) internal {
        
        //address can't be zero
        if (address(_securityManager) == address(0)) 
            revert ZeroAddressArgument(); 
            
        //this line will fail if security manager is invalid address
        _securityManager.hasRole(ADMIN_ROLE, address(this)); 
        
        //set the security manager
        securityManager = _securityManager;
    }
    
    //future-proof, as this is inherited by upgradeable contracts
    uint256[50] private __gap;
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

library AddressUtil {
    /**
     * Determines whether or not the given address refers to a valid ERC20 token contract. 
     * 
     * @param _addr The address in question. 
     * @return bool True if ERC20 token. 
     */
    function isERC20Contract(address _addr) internal view returns (bool) {
        if (_addr != address(0)) {
            if (AddressUpgradeable.isContract(_addr)) {
                IERC20 token = IERC20(_addr); 
                return token.totalSupply() >= 0;  
            }
        }
        return false;
    }
}

/**
 * @title DepositVault 
 * 
 * This contract is part of a process by which users can deposit to a Vault directly, by simple ERC20 
 * transfer. 
 * 
 * The process: 
 * 1. address 0xadd transfers N of baseToken into THIS contract (the deposit vault), in transaction TX
 * 2. that transfer will be scraped from the blockchain by an off-chain process 
 * 3. an authorized caller will call this contract's finalizeDeposit method, passing 
 *      - N (the amount) 
 *      - TX (the original tx id, now the 'deposit id')
 *      - 0xadd (the eventual beneficiary of the deposit)
 * 
 * The call to the finalizeDeposit method finalizes the transfer, finally pushing the token amount intended
 * for the Vault, to the actual Vault. 
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
contract DepositVault is ManagedSecurity, ReentrancyGuard {
    
    //tokens
    IERC20 public baseToken; 
    
    //vault 
    IVault public vault;
    
    //errors 
    error ZeroAmountArgument(); 
    error InvalidTokenContract(address); 
    error TokenTransferFailed();
    
    //events 
    event DepositExecuted(bytes32 indexed transactionId, address indexed onBehalfOf, uint256 amount); 
    
    /**
     * Creates an instance of a DepositVault, associated with a particular vault, base currency, and under 
     * the security umbrella of a security manager. 
     * 
     * Reverts: 
     * - { ZeroAddressArgument } - If any of the given addresses are zero. 
     * - { InvalidTokenContract } - If the given base token address is not a valid ERC20 contract
     * - 'Address: low-level delegate call failed' (if `_securityManager` is not legit)
     */
    constructor(IVault _vault, IERC20 _baseToken) {
        
        //validate base token address 
        if (address(_baseToken) == address(0)) 
            revert ZeroAddressArgument(); 
        if (!AddressUtil.isERC20Contract(address(_baseToken)))
            revert InvalidTokenContract(address(_baseToken)); 
            
        //validate vault address
        if (address(_vault) == address(0)) 
            revert ZeroAddressArgument(); 
        
        baseToken = _baseToken;
        vault = _vault;
        
        _setSecurityManager(vault.securityManager()); 
    }
    
    /**
     * Causes this contract to transfer the specified amount of its own {baseToken} balance to the 
     * Vault that is associated with this instance in its {vault} property. 
     * 
     * Emits: 
     * - { DepositExecuted } - on successful deposit
     * - { ERC20-Transfer } - on successful ERC20 transfer within the deposit 
     * 
     * Reverts: 
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     * - {ZeroAmountArgument} - if the amount specified is zero. 
     * - {TokenTransferFailed} - if either `baseToken`.transferFrom or `vaultToken`.transfer returns false.
     * - {ActionOutOfPhase} - if Vault is not in Deposit phase. 
     * - {NotWhitelisted} - if caller or `forAddress` is not whitelisted (if the Vault has whitelisting)
     * - 'Pausable: Paused' -  if Vault contract is paused. 
     * - 'ERC20: transfer amount exceeds balance' - if user has less than the given amount of Base Token
     * 
     * @param amount The amount of {baseToken} to transfer from this contract to the {vault}. 
     * @param transactionId Unique of the transaction, which is emitted in the event, and should be equal to the 
     * transaction id of the corresponding original transfer of the same amount, by `onBehalfOf`, to this contract.
     * @param onBehalfOf The address which originally transferred the same amount into this contract, and 
     * which will receive the appropriate VaultToken amount as a result of this deposit. 
     */
    function finalizeDeposit( 
        uint256 amount, 
        bytes32 transactionId, 
        address onBehalfOf
    ) external onlyRole(DEPOSIT_MANAGER_ROLE) nonReentrant {
        baseToken.approve(address(vault), amount); 
        vault.depositFor(amount, onBehalfOf); 
        emit DepositExecuted(transactionId, onBehalfOf, amount); 
    }
    
    /**
     * Allows admin to withdraw Base Token via ERC20 transfer.
     * 
     * @param amount The amount to withdraw
     * 
     * Reverts:
     * - {UnauthorizedAccess}: if caller is not authorized with the appropriate role
     */
    function adminWithdraw(uint256 amount) external nonReentrant onlyRole(ADMIN_ROLE) {
        baseToken.transfer(msg.sender, amount); 
    }
}