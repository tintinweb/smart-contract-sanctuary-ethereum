// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./compliance/WhitelistCompliant.sol";
import "./compliance/SuspendCompliant.sol";
import "./access-guard/AccessGuard.sol";

/// @title OSLToken
/// @notice Extended ERC20 permissioned contract with whitelist and suspend compliance verification.
contract OSLToken is
    ERC20,
    Pausable,
    AccessGuard,
    WhitelistCompliant,
    SuspendCompliant
{
    /*==================== Events ====================*/

    event OperatorTransfer(
        address indexed operator,
        address sender,
        address recipient,
        uint256 amount
    );

    event OperatorTransferBatch(
        address indexed operator,
        address[] senders,
        address[] recipients,
        uint256[] amounts
    );

    event OperatorBurn(
        address indexed operator,
        address account,
        uint256 amount
    );

    event OperatorBurnBatch(
        address indexed operator,
        address[] accounts,
        uint256[] amounts
    );

    event OperatorMint(
        address indexed operator,
        address account,
        uint256 amount
    );

    event OperatorMintBatch(
        address indexed operator,
        address[] accounts,
        uint256[] amounts
    );

    /*==================== Global variables ====================*/

    /// @dev Boolean set in the constructor to enable whitelist
    bool public immutable whitelistEnabled;

    /// @dev Boolean set in the constructor to enable `operatorTransferBatch`
    bool public immutable operatorTransferEnabled;

    /// @dev Boolean set in the constructor to enable `operatorBurnBatch`
    bool public immutable operatorBurnEnabled;

    /// @dev Variable to hold the number of decimals
    uint8 private immutable _decimals;

    /// @notice
    /// @dev
    /// @param enableWhitelist_ (bool) enable whitelist or not
    /// @param enableOperatorTransfer_ (bool) enable operator batch transfer
    /// @param enableOperatorBurns_ (bool) enable operator batch burn
    /// @param name_ (string) name of the ERC20 token
    /// @param symbol_ (string) symbol of the ERC20 token
    /// @param defaultAdmin_ (address) wallet address of the initial admin
    constructor(
        bool enableWhitelist_,
        bool enableOperatorTransfer_,
        bool enableOperatorBurns_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address defaultAdmin_
    ) ERC20(name_, symbol_) {
        whitelistEnabled = enableWhitelist_;
        operatorTransferEnabled = enableOperatorTransfer_;
        operatorBurnEnabled = enableOperatorBurns_;
        _decimals = decimals_;

        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
    }

    /// @notice Burn an amount from the owners balance. Can only be called if the owner of the wallet
    /// is whitelisted & not suspended
    /// @param amount (uint256) amount to be burned
    function burn(uint256 amount) external whenNotPaused {
        require(
            !isSuspended(_msgSender()),
            "OSLToken: Address must not be suspended"
        );
        require(
            _verifyWhitelist(_msgSender()),
            "OSLToken: Address must be whitelisted"
        );

        _burn(_msgSender(), amount);
    }

    /*==================== Operator Only Functions ====================*/

    /// @notice Pause the contract. Can only be called by operators.
    /// @dev
    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract. Can only be called by operators.
    /// @dev
    function proceed() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /// @notice Only available if `operatorTransferEnabled` is set true in the constructor. Transfer from an address to
    /// another address a specific amount. It can only be called by operators. This function is similar to the `operatorTransferBatch`
    /// but works for single accounts
    /// @dev Each index of each array is mapped directly so senders[1] will transfer to recipients[1], amount[1] and so on
    /// @param sender (address) Account transfer sender
    /// @param recipient (address) Account transfer recipient
    /// @param amount (uint256) Amount to be transferred
    function operatorTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(
            operatorTransferEnabled,
            "OSLToken: Operator transfer not enabled"
        );
        require(
            !isSuspended(sender) && !isSuspended(recipient),
            "OSLToken: Addresses must not be suspended"
        );

        _transfer(sender, recipient, amount);

        emit OperatorTransfer(_msgSender(), sender, recipient, amount);
    }

    /// @notice Only available if `operatorTransferEnabled` is set true in the constructor. Transfer from a list of addresses to
    /// another list of addresses specific amounts. It can only be called by operators. This function will only check if the accounts
    /// are not suspended.
    /// @dev Each index of each array is mapped directly so senders[1] will transfer to recipients[1], amount[1] and so on
    /// @param senders (address[]) List of source address
    /// @param recipients (address[]) List of target addresses
    /// @param amounts (uint256[]) List of amounts to be transferred
    function operatorTransferBatch(
        address[] calldata senders,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(
            operatorTransferEnabled,
            "OSLToken: Operator transfer not enabled"
        );
        require(
            senders.length == recipients.length &&
                recipients.length == amounts.length,
            "OSLToken: Mismatching argument sizes"
        );

        for (uint256 index = 0; index < senders.length; index++) {
            require(
                !isSuspended(senders[index]) && !isSuspended(recipients[index]),
                "OSLToken: Addresses must not be suspended"
            );
            _transfer(senders[index], recipients[index], amounts[index]);
        }

        emit OperatorTransferBatch(_msgSender(), senders, recipients, amounts);
    }

    /// @notice Only available if `operatorBurnEnabled` is set true in the constructor. Burn an amount from an account.
    /// Can only be called by operators. It can burn tokens even if the account is suspended or not whitelisted.
    /// @param account (address) Account to burn from
    /// @param amount (uint256) Amount to be burned
    function operatorBurn(address account, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
    {
        require(operatorBurnEnabled, "OSLToken: Operator burn not enabled");

        _burn(account, amount);

        emit OperatorBurn(_msgSender(), account, amount);
    }

    /// @notice Only available if `operatorBurnEnabled` is set true in the constructor. Burn from a list of addresses a list of amounts.
    /// Can only be called by operators.
    /// @dev Each index of each array is mapped directly so accounts[1] will get a burn with amount[1] tokens and so on
    /// @param accounts (address[]) List of accounts to burn from
    /// @param amounts (uint256[]) List of amounts to be burned
    function operatorBurnBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(operatorBurnEnabled, "OSLToken: Operator burn not enabled");
        require(
            accounts.length == amounts.length,
            "OSLToken: Mismatching argument sizes"
        );

        for (uint256 index = 0; index < accounts.length; index++) {
            _burn(accounts[index], amounts[index]);
        }

        emit OperatorBurnBatch(_msgSender(), accounts, amounts);
    }

    /// @notice Mint an amount to an account. Can only be called by operators.
    /// @dev Similar to `operatorMintBatch` but for single accounts
    /// @param account (address) Account to mint to
    /// @param amount (uint256) Amount to be minted
    function operatorMint(address account, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
    {
        require(
            !isSuspended(account),
            "OSLToken: Address must not be suspended"
        );

        _mint(account, amount);

        emit OperatorMint(_msgSender(), account, amount);
    }

    /// @notice Mint to list of addresses a list of amounts. Can only be called by operators.
    /// @dev Each index of each array is mapped directly so accounts[1] will get a minted amount[1] tokens and so on
    /// @param accounts (address[]) List of accounts to mint to
    /// @param amounts (uint256[]) List of amounts to be minted
    function operatorMintBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(
            accounts.length == amounts.length,
            "OSLToken: Mismatching argument sizes"
        );

        for (uint256 index = 0; index < accounts.length; index++) {
            require(
                !isSuspended(accounts[index]),
                "OSLToken: Address must not be suspended"
            );
            _mint(accounts[index], amounts[index]);
        }

        emit OperatorMintBatch(_msgSender(), accounts, amounts);
    }

    /*==================== Internal Functions ====================*/

    /// @notice If whitelist enabled verify if the account is whitelisted
    /// @dev Will return true if `whitelistEnabled` is `false` or if `whitelistEnabled` is `true` and the account
    /// argument is whitelisted
    /// @param account (address) Account to verify if whitelisted
    function _verifyWhitelist(address account) internal view returns (bool) {
        return !whitelistEnabled || isWhitelisted(account);
    }

    /*==================== Override ERC20 Functions ====================*/

    /// @notice Override default `decimals` function from ERC20 to return from the value from the global state
    /// @return (uint256) Decimal value of ERC20
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice Override default `transferFrom` function from ERC20 to check whitelist & suspend status also block while paused
    /// @dev Overwrite default `transferFrom` functionality while using the super inheritance call after verifying pause and compliance status
    /// @param sender (address) Sender of tokens
    /// @param recipient (address) Recipient of tokens
    /// @param amount (uint256) Amount of tokens to be transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        require(
            !isSuspended(sender) && !isSuspended(recipient),
            "OSLToken: Addresses must not be suspended"
        );
        require(
            _verifyWhitelist(sender) && _verifyWhitelist(recipient),
            "OSLToken: Addresses must be whitelisted"
        );

        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Override default `transfer` function from ERC20 to check whitelist & suspend status also block while paused
    /// @dev Overwrite default `transfer` functionality while using the super inheritance call after verifying pause and compliance status
    /// @param recipient (address) Recipient of tokens
    /// @param amount (uint256) Amount of tokens to be transferred
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(
            !isSuspended(_msgSender()) && !isSuspended(recipient),
            "OSLToken: Addresses must not be suspended"
        );
        require(
            _verifyWhitelist(_msgSender()) && _verifyWhitelist(recipient),
            "OSLToken: Addresses must be whitelisted"
        );

        return super.transfer(recipient, amount);
    }
}

// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessGuard is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
}

// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../access-guard/AccessGuard.sol";

/// @title SuspendCompliant
/// @notice Suspend compliance module for the osl token
abstract contract SuspendCompliant is AccessGuard {
    /*==================== Events ====================*/

    event Suspend(address indexed operator, address indexed account);
    event Unsuspend(address indexed operator, address indexed account);
    event SuspendBatch(address indexed operator, address[] accounts);
    event UnsuspendBatch(address indexed operator, address[] accounts);

    /*==================== Global variables ====================*/

    /// @dev Mapping that will link addresses to booleans representing the
    /// suspended state of each address. The `True` value mapped to an address
    /// will represent that the address is suspended, and `False` that it is not.
    /// By default, no address is suspended.
    mapping(address => bool) private _suspended;

    /*==================== Public/external functions ====================*/

    /// @notice Check if a specific address is suspended or not
    /// @dev return true if the account is suspended and false if it is not
    /// @param account (address) address to check if suspended
    function isSuspended(address account) public view returns (bool) {
        return _suspended[account];
    }

    /// @notice Suspend an account
    /// @dev In order to suspend an account, the caller needs to be an operator. It will
    /// emit a `Suspend` event.
    /// @param account (address) Account to suspended
    function suspend(address account) external onlyRole(OPERATOR_ROLE) {
        _suspend(account);
    }

    /// @notice Unsuspend an account
    /// @dev In order to unsuspend an account, the caller needs to be an operator. It will
    /// emit an `Unsuspend` event.
    /// @param account (address) Account to unsuspend
    function unsuspend(address account) external onlyRole(OPERATOR_ROLE) {
        _unsuspend(account);
    }

    /// @notice Suspend a list of accounts
    /// @dev In order to suspend a list of accounts, the caller needs to be an operator.
    /// If any suspend action on an account reverts, the function will revert. It will emit an
    /// `Suspend` event for each account and at the end an `SuspendBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be suspended
    function suspendBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _suspend(accounts[index]);
        }

        emit SuspendBatch(_msgSender(), accounts);
    }

    /// @notice Unsuspend a list of accounts
    /// @dev In order to unsuspend a list of accounts, the caller needs to be an operator.
    /// If any unsuspend action on an account reverts, the function will revert. It will emit an
    /// `Unsuspend` event for each account and at the end an `UnsuspendBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be unsuspend
    function unsuspendBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _unsuspend(accounts[index]);
        }

        emit UnsuspendBatch(_msgSender(), accounts);
    }

    /*==================== Internal Functions ====================*/

    /// @notice Suspend an account
    /// @dev The address from the account argument will be flagged as suspended
    /// in the `_suspended` mapping. It will revert if the address is already suspended
    /// or if you try to suspend the zero address (address(0)). It will emit a `Suspend` event
    /// @param account (address) Address to be suspended
    function _suspend(address account) internal {
        require(
            !_suspended[account],
            "SuspendCompliant: Account is already suspended"
        );
        require(
            account != address(0),
            "SuspendCompliant: Cannot suspend zero address"
        );

        _suspended[account] = true;

        emit Suspend(_msgSender(), account);
    }

    /// @notice Unsuspend an account
    /// @dev The address from the account argument will be flagged as unsuspend
    /// in the `_suspended` mapping. It will revert if the address is not suspended.
    /// It will emit a `Suspend` event
    /// @param account (address) Address to be unsuspend
    function _unsuspend(address account) internal {
        require(
            _suspended[account],
            "SuspendCompliant: Account is not suspended"
        );

        _suspended[account] = false;

        emit Unsuspend(_msgSender(), account);
    }
}

// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../access-guard/AccessGuard.sol";

/// @title WhitelistCompliant
/// @notice Whitelist compliance module for the osl token
abstract contract WhitelistCompliant is AccessGuard {
    /*==================== Events ====================*/

    event Whitelist(address indexed operator, address indexed account);
    event RemoveWhitelist(address indexed operator, address indexed account);
    event WhitelistBatch(address indexed operator, address[] accounts);
    event RemoveWhitelistBatch(address indexed operator, address[] accounts);

    /*==================== Global variables ====================*/

    /// @dev Mapping that will link addresses to booleans representing the
    /// whitelist state of each address. The `True` value mapped to an address
    /// will represent that the address is whitelisted, and `False` that it is not.
    /// By default, no address is whitelisted.
    mapping(address => bool) private _whitelisted;

    /*==================== Public/external functions ====================*/

    /// @notice Check if a specific address is whitelisted or not
    /// @dev return true if the account is whitelisted and false if it is not
    /// @param account (address) address to check if whitelisted
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisted[account];
    }

    /// @notice Whitelist an account
    /// @dev In order to whitelist an account, the caller needs to be an operator. It will
    /// emit a `Whitelist` event.
    /// @param account (address) Account to whitelist
    function whitelist(address account) external onlyRole(OPERATOR_ROLE) {
        _whitelist(account);
    }

    /// @notice Remove an account from whitelist
    /// @dev In order to remove an account from the whitelist, the caller needs to be an operator. It will
    /// emit a `RemoveWhitelist` event.
    /// @param account (address) Account to be removed from the whitelist
    function removeWhitelist(address account) external onlyRole(OPERATOR_ROLE) {
        _removeWhitelist(account);
    }

    /// @notice Whitelist a list of accounts
    /// @dev In order to whitelist a list of accounts, the caller needs to be an operator.
    /// If any whitelist action on an account reverts, the function will revert. It will emit an
    /// `Whitelist` event for each account and at the end an `WhitelistBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be whitelisted
    function whitelistBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _whitelist(accounts[index]);
        }

        emit WhitelistBatch(_msgSender(), accounts);
    }

    /// @notice Remove a list of accounts from the whitelist
    /// @dev In order to remove a list of accounts from the whitelist, the caller needs to be an operator.
    /// If any removal action on any account reverts, the function will revert. It will emit an
    /// `RemoveWhitelist` event for each account and at the end an `RemoveWhitelistBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be whitelisted
    function removeWhitelistBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _removeWhitelist(accounts[index]);
        }

        emit RemoveWhitelistBatch(_msgSender(), accounts);
    }

    /*==================== Internal Functions ====================*/

    /// @notice Whitelist an account
    /// @dev The address from the account argument will be flagged as whitelisted
    /// in the `_whitelisted` mapping. It will revert if the address is already Whitelisted
    /// or if you try to whitelist the zero address (address(0)). It will emit a `Whitelist` event
    /// @param account (address) Address to pe suspended
    function _whitelist(address account) internal {
        require(
            !_whitelisted[account],
            "WhitelistComplaint: Account is already whitelisted"
        );
        require(
            account != address(0),
            "WhitelistComplaint: Cannot whitelist zero address"
        );

        _whitelisted[account] = true;

        emit Whitelist(_msgSender(), account);
    }

    /// @notice Remove an account from whitelist
    /// @dev The address from the account argument will be flagged as not whitelisted
    /// in the `_whitelisted` mapping. It will revert if the address is not on the whitelist.
    /// It will emit a `RemoveWhitelist` event.
    /// @param account (address) Address to pe suspended
    function _removeWhitelist(address account) internal {
        require(
            _whitelisted[account],
            "WhitelistComplaint: Account is not whitelisted"
        );

        _whitelisted[account] = false;

        emit RemoveWhitelist(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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