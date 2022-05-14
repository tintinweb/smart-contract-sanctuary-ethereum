/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: Context

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

// Part: IERC165

/// @dev IERC165 definition taken from : https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// Part: IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * @dev Taken from: OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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

// Part: Ownable

// Create ownable contract, don't support OwnershipTransfer just yet
abstract contract Ownable {
    // Owner of the contract 
    address internal _owner;

    /// @dev Setup the owner 
    constructor() {
        _owner = msg.sender;
    }

    /// @dev Public function to check owner 
    /// @return address of the owner of this contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev owner checking modifier 
    modifier OnlyOwner() {
        require(owner() == msg.sender, "AccessControl: Unauthorized access not allowed");
        _;
    }
}

// Part: ERC165

abstract contract ERC165 is IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Part: IERC20Metadata

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 * @dev Taken from: OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
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

// Part: ERC20

/// @dev Taken from : OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)
/// @dev Update ERC20 contract to support Soul-bounding, once assigned - cannot be transferred 

// Revert error OperationNotAllowed when user tries to perform restricted actions, transfer - transferFrom - approve etc.
// error OperationNotAllowed();
// Revert error for unsupported actions
// error UnsupportedAction();

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

 // Context : retrieval of msg.sender and msg.data 
 // ERC165 : Implementation of supportsInterface(byte4) 
 // IERC165 : supportsInterface(byte4) external view 
 // IERC20Metadata : External functions of _name, _symbol, _decimal
 // Keeping decimals fixed at 18

contract ERC20 is Context, ERC165, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
     * Restricted
     */
    function transfer(address, uint256) public virtual override returns (bool) {
        //revert OperationNotAllowed();
        revert();
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Unsupported
     */
    function allowance(address, address) public view virtual override returns (uint256) {
        //revert UnsupportedAction();
        revert();
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Restricted 
     */
    function approve(address, uint256) public virtual override returns (bool) {
        //revert OperationNotAllowed();
        revert();
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Restricted
     */
    function transferFrom(address, address, uint256) public virtual override returns (bool) {
        //revert OperationNotAllowed();
        revert();
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * Unsupported
     */
    function increaseAllowance(address, uint256) public virtual returns (bool) {
        //revert UnsupportedAction();
        revert();
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * Unsupported
     */
    function decreaseAllowance(address, uint256) public virtual returns (bool) {
        //revert UnsupportedAction();
        revert();
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
     * Restricted
     */
    function _approve(address, address, uint256) internal virtual {
        //revert OperationNotAllowed();
        revert();
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

// File: EXPToken.sol

/// @author 0micronat_. - https://github.com/SolDev-HP (Playground)
/// @dev EXPToken (EXP) contract that handles minting and assigning EXP to the users 
/// Only primary admin can add other admins 
/// All admin can _mint token to given address, and _burn token from given address 

contract EXPToken is ERC20, Ownable {
    // ================= State Vars ==================
    // Token admins 
    mapping(address => bool) internal _TokenAdmins;
    // Per user experience point capping 
    uint256 internal constant MAXEXP = 100000000000000000000;


    // ================= EVENTS ======================
    event TokenAdminUpdated(address indexed admin_, bool indexed isAdmin_);

    /// @dev Initialize contract by providing Token name ex: "EXPToken" and symbol ex: "EXP"
    /// This should be able to create ERC20 token, initiator will be the primary admin who 
    /// can add or remove other admins 
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        /// Make msg sender the first admin 
        _TokenAdmins[msg.sender] = true;
    }

    /// @dev Allow adding/removing admins for EXPToken
    function setTokenAdmins(address admin_, bool isSet_) public OnlyOwner {
        // Add/Remove token admins 
        _TokenAdmins[admin_] = isSet_;
        // Emit the admin update event 
        emit TokenAdminUpdated(admin_, isSet_);
    }

    /// @dev gainExperience function to add experience points to user's EXP balance 
    /// Need to make sure we cap experience to max exp limit
    function gainExperience(address gainer_, uint256 gainAmount_) public {
        // Make sure only admins can call this function 
        require(_TokenAdmins[msg.sender] == true, "EXPToken (AccessControl): Not authorized.");
        // Make use of state variable only once if it's being used multiple times within function
        // In this case, balanceOf will access user's balance state var 
        uint256 _balance = balanceOf(gainer_);
        // Make sure user doesn't already have max exprience points 
        require(_balance < MAXEXP, "EXPToken: User already at max experience points possible.");
        // Make sure it doesn't go above capped possible points after _minting 
        require(_balance + gainAmount_ <= MAXEXP, "EXPToken: This mint will send user above capped exprience point. Not allowed.");
        // Mint tokens to the address
        _mint(gainer_, gainAmount_);
    }

    /// @dev reduceExperience function to remove exp from user's balance 
    /// Need to make sure, it doesn't go below 0 after deduction and user's balance isn't already zero
    function reduceExperience(address looser_, uint256 lostAmount_) public {
        // Make sure only admins can call this function 
        require(_TokenAdmins[msg.sender] == true, "EXPToken (AccessControl): Not authorized.");
        // Make use of state variable only once if it's being used multiple times within function
        // In this case, balanceOf will access user's balance state var 
        uint256 _balance = balanceOf(looser_);
        // Make sure user's balance isn't already zero 
        require(_balance > 0, "EXPToken: User doen't have enough experience points");
        // Make sure our calculation doesn't bring it below zero 
        require(_balance - lostAmount_ > 0, "EXPToken: This action will bring user experience below zero. Not allowed.");
        // Burn given amount from user's balance 
        _burn(looser_, lostAmount_);
    }
}