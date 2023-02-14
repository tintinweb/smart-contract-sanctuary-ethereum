// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IERC20 } from "./IERC20.sol";

/// @title ERC20
/// @author Paul Razvan Berg
contract ERC20 is IERC20 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC20
    string public override name;

    /// @inheritdoc IERC20
    string public override symbol;

    /// @inheritdoc IERC20
    uint8 public immutable override decimals;

    /// @inheritdoc IERC20
    uint256 public override totalSupply;

    /// INTERNAL STORAGE ///

    /// @dev Internal mapping of balances.
    mapping(address => uint256) internal _balances;

    /// @dev Internal mapping of allowances.
    mapping(address => mapping(address => uint256)) internal _allowances;

    /// CONSTRUCTOR ///

    /// @notice All three of these arguments are immutable: they can only be set once during construction.
    /// @param name_ ERC-20 name of this token.
    /// @param symbol_ ERC-20 symbol of this token.
    /// @param decimals_ ERC-20 decimal precision of this token.
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @inheritdoc IERC20
    function decreaseAllowance(address spender, uint256 value) public virtual override returns (bool) {
        // Calculate the new allowance.
        uint256 newAllowance = _allowances[msg.sender][spender] - value;

        // Make the approval.
        _approve(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IERC20
    function increaseAllowance(address spender, uint256 value) public virtual override returns (bool) {
        // Calculate the new allowance.
        uint256 newAllowance = _allowances[msg.sender][spender] + value;

        // Make the approval.
        _approve(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // Checks: the spender's allowance is sufficient.
        address spender = msg.sender;
        uint256 currentAllowance = _allowances[from][spender];
        if (currentAllowance < amount) {
            revert ERC20_InsufficientAllowance(from, spender, currentAllowance, amount);
        }

        // Effects: update the allowance.
        unchecked {
            _approve(from, spender, currentAllowance - amount);
        }

        // Checks, Effects and Interactions: make the transfer.
        _transfer(from, to, amount);

        return true;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `value` as the allowance of `spender` over the `owner`s tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// Requirements:
    ///
    /// - `owner` must not be the zero address.
    /// - `spender` must not be the zero address.
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        // Checks: `owner` is not the zero address.
        if (owner == address(0)) {
            revert ERC20_ApproveOwnerZeroAddress();
        }

        // Checks: `spender` is not the zero address.
        if (spender == address(0)) {
            revert ERC20_ApproveSpenderZeroAddress();
        }

        // Effects: update the allowance.
        _allowances[owner][spender] = value;

        // Emit an event.
        emit Approval(owner, spender, value);
    }

    /// @notice Destroys `amount` tokens from `holder`, decreaasing the token supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `holder` must have at least `amount` tokens.
    function _burn(address holder, uint256 amount) internal {
        // Checks: `holder` is not the zero address.
        if (holder == address(0)) {
            revert ERC20_BurnHolderZeroAddress();
        }

        // Effects: burn the tokens.
        _balances[holder] -= amount;

        // Effects: reduce the total supply.
        unchecked {
            // Underflow not possible: amount <= account balance <= total supply.
            totalSupply -= amount;
        }

        // Emit an event.
        emit Transfer(holder, address(0), amount);
    }

    /// @notice Prints new `amount` tokens into existence and assigns them to `beneficiary`, increasing the
    /// total supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - The beneficiary's balance and the total supply must not overflow.
    function _mint(address beneficiary, uint256 amount) internal {
        // Checks: `beneficiary` is not the zero address.
        if (beneficiary == address(0)) {
            revert ERC20_MintBeneficiaryZeroAddress();
        }

        /// Effects: increase the total supply.
        totalSupply += amount;

        /// Effects: mint the new tokens.
        unchecked {
            // Overflow not possible: `balance + amount` is at most `totalSupply + amount`, which is checked above.
            _balances[beneficiary] += amount;
        }

        // Emit an event.
        emit Transfer(address(0), beneficiary, amount);
    }

    /// @notice Moves `amount` tokens from `from` to `to`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `from` must not be the zero address.
    /// - `to` must not be the zero address.
    /// - `from` must have a balance of at least `amount`.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // Checks: `from` is not the zero address.
        if (from == address(0)) {
            revert ERC20_TransferFromZeroAddress();
        }

        // Checks: `to` is not the zero address.
        if (to == address(0)) {
            revert ERC20_TransferToZeroAddress();
        }

        // Checks: `from` has enough balance.
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert ERC20_FromInsufficientBalance(fromBalance, amount);
        }

        // Effects: update the balance of `from` and `to`..
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by the total supply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        // Emit an event.
        emit Transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { ERC20 } from "./ERC20.sol";

/// @title ERC20GodMode
/// @author Paul Razvan Berg
/// @notice Allows anyone to mint or burn any amount of tokens to any account.
contract ERC20GodMode is ERC20 {
    /// EVENTS ///

    event Burn(address indexed holder, uint256 amount);

    event Mint(address indexed beneficiary, uint256 amount);

    /// CONSTRUCTOR ///

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {}

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Destroys `amount` tokens from `holder`, decreaasing the token supply.
    /// @param holder The account whose tokens to burn.
    /// @param amount The amount of tokens to destroy.
    function burn(address holder, uint256 amount) public {
        _burn(holder, amount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the
    /// total supply.
    /// @param beneficiary The account for which to mint the tokens.
    /// @param amount The amount of tokens to print into existence.
    function mint(address beneficiary, uint256 amount) public {
        _mint(beneficiary, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title IERC20
/// @author Paul Razvan Berg
/// @notice Implementation for the ERC-20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of ERC-20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the ERC may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IERC20 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when attempting to approve with the zero address as the owner.
    error ERC20_ApproveOwnerZeroAddress();

    /// @notice Emitted when attempting to approve the zero address as the spender.
    error ERC20_ApproveSpenderZeroAddress();

    /// @notice Emitted when attempting to burn tokens from the zero address.
    error ERC20_BurnHolderZeroAddress();

    /// @notice Emitted when attempting to transfer more tokens than there are in the from account.
    error ERC20_FromInsufficientBalance(uint256 senderBalance, uint256 transferAmount);

    /// @notice Emitted when spender attempts to transfer more tokens than the owner had given them allowance for.
    error ERC20_InsufficientAllowance(address owner, address spender, uint256 allowance, uint256 transferAmount);

    /// @notice Emitted when attempting to mint tokens to the zero address.
    error ERC20_MintBeneficiaryZeroAddress();

    /// @notice Emitted when attempting to transfer tokens from the zero address.
    error ERC20_TransferFromZeroAddress();

    /// @notice Emitted when the attempting to transfer tokens to the zero address.
    error ERC20_TransferToZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when an approval occurs.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param value The maximum value that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Emitted when a transfer occurs.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `value` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {IERC20-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `value`.
    function decreaseAllowance(address spender, uint256 value) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` must not be the zero address.
    function increaseAllowance(address spender, uint256 value) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `to` must not be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the ERC. See the note at the beginning of {ERC-20}.
    ///
    /// Requirements:
    ///
    /// - `from` and `to` must not be the zero address.
    /// - `from` must have a balance of at least `amount`.
    /// - The caller must have approed `from` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}