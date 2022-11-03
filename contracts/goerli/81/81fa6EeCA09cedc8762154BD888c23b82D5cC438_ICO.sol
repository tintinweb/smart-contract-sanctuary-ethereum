//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import { SpaceCoin } from "./SpaceCoin.sol";

/// @notice Throw when attempt to execute operations without authorization (not owner)
error ICO__Unauthorized();

/// @notice Throw when attempt to execute operations not allowed by the contract's logic
error ICO__OperationNotAllowed();

/// @notice Throw when attempt to execute operations when contract is paused
error ICO__OperationsPaused();

/// @notice Throw when attempt to invest more than the maximum individual limit
error ICO__IndividualMaxLimitReached();

/// @notice Throw when attempt to redeem tokens but there's not enough balance
error ICO__InsufficientBalance();

/// @notice Throw when attempt to invest a value that exceeds the maximum total limit
error ICO__TotalMaxLimitReached();

contract ICO {
    // limit of investments to be collected for an individual investor on the Seed phase
    uint constant public SEED_MAX_INDIVIDUAL_LIMIT = 1_500 ether;

    // limit of investments to be collected for the entire ICO on the Seed phase
    uint constant public SEED_MAX_TOTAL_LIMIT = 15_000 ether;

    // limit of investments to be collected for an individual investor on the Open phase
    uint constant public MAX_INDIVIDUAL_LIMIT = 1_000 ether;

    // limit of investments to be collected for the entire ICO on the open & general phases
    uint constant public MAX_TOTAL_LIMIT = 30_000 ether;

    // ratio of SPC tokens to be received for each ETH invested (5 SPC <> 1 ETH)
    uint constant public SPC_EXCHANGE_RATE = 5;

    // total value invested from all investors
    uint public totalInvested;

    // value that pauses the ICO
    bool public isPaused;

    // owner of the ICO & SpaceCoin contracts
    address immutable public owner;

    // token contract
    SpaceCoin immutable public spaceCoin;

    // allowlist of private investors of the seed phase
    mapping(address => bool) public isPrivateInvestor;

    // amount invested by each investor
    mapping(address => uint) public investments;

    // investment phases
    Phase public phase;
    enum Phase {
        Seed,
        General,
        Open
    }

    /**
     * @notice Emitted when an investment is made
     * @param investor Address of the investor
     * @param amount Amount of ETH invested
     */
    event Invest(address indexed investor, uint amount);

    /**
     * @notice Emitted when an investor redeem their tokens
     * @param investor Address of the investor
     * @param tokensAmount Amount of tokens sent
     */
    event Redeem(address indexed investor, uint tokensAmount);

    /**
     * @notice Emitted when the owner add or remove an address from the allowlist
     * @param investor Address of the investor
     * @param state Represents if the address was added or removed from the list
     */
    event TogglePrivateInvestor(address indexed investor, bool state);

    /**
     * @notice Emitted when the owner moves the ICO to another phase
     * @param phase the new ICO phase
     */
    event MovePhase(Phase indexed phase);

    /**
     * @notice Emitted when the owner toggles the pause state
     * @param isPaused Represents if the contract is paused or not
     */
    event Pause(bool indexed isPaused);

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner {
        if (msg.sender != owner) {
            revert ICO__Unauthorized();
        }
        _;
    }

    /// @dev Throws if called when the contract is paused
    modifier notPaused {
        if (isPaused) {
            revert ICO__OperationsPaused();
        }
        _;
    }

    constructor(address _owner, address _treasury) {
        owner = _owner;
        phase = Phase.Seed;
        spaceCoin = new SpaceCoin(_owner, _treasury, address(this));
    }

    /**
     * @notice Invest an amount of ETH to the ICO
     */
    function invest() external payable notPaused {
        // check to ensure that the investor is on the Seed phase allowlist
        if (phase == Phase.Seed && !isPrivateInvestor[msg.sender]) {
            revert ICO__OperationNotAllowed();
        }

        // check to ensure the investment satisfies the limits
        _validateLimits(msg.sender, msg.value);

        totalInvested += msg.value;
        investments[msg.sender] += msg.value;

        emit Invest(msg.sender, msg.value);
    }

    /**
     * @notice Redeem SPC tokens based on the amount invested
     */
    function redeem() external notPaused {
        if (phase != Phase.Open) {
            revert ICO__OperationNotAllowed();
        }

        if (investments[msg.sender] == 0) {
            revert ICO__InsufficientBalance();
        }

        uint _tokensOwed = investments[msg.sender] * SPC_EXCHANGE_RATE;
        investments[msg.sender] = 0;
        spaceCoin.transfer(msg.sender, _tokensOwed);

        emit Redeem(msg.sender, _tokensOwed);
    }

    /**
     * @notice Add or remove a private investor from the allowlist
     * @dev To remove an address, it just changes the state to `false`
     * instead of deleting the address from the mapping
     * @param _investor Address of the investor
     * @param _state Boolean that represents if an address is on the allowlist
     */
    function togglePrivateInvestor(address _investor, bool _state) external onlyOwner {
        isPrivateInvestor[_investor] = _state;
        emit TogglePrivateInvestor(_investor, _state);
    }

    /// @notice Move the ICO to the General phase
    function moveToGeneralPhase() external onlyOwner {
        if (phase != Phase.Seed) {
            revert ICO__OperationNotAllowed();
        }

        phase = Phase.General;
        emit MovePhase(phase);
    }

    /// @notice Move the ICO to the Open phase
    function moveToOpenPhase() external onlyOwner {
        if (phase != Phase.General) {
            revert ICO__OperationNotAllowed();
        }

        phase = Phase.Open;
        emit MovePhase(phase);
    }

    /**
     * @notice Pause the ICO
     * @dev The pause state affects the `transfer` and `redeem` functions
     * @param _isPaused Boolean that represents if the contract is paused or not
     */
    function setPause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
        emit Pause(_isPaused);
    }

    /**
     * @notice Check the contract limits for a new investment
     * @dev This includes checks on the maximum individual contribution
     * and the maximum total contributions
     */
    function _validateLimits(address _investor, uint _newAmount) private view {
        // get the total maximum investment limit based on the current phase
        // the sum of the contributions from all the investors can't exceed this limit
        uint _maxTotalLimit = phase == Phase.Seed ? SEED_MAX_TOTAL_LIMIT : MAX_TOTAL_LIMIT;

        // get the maximum individual investment limit based on the current phase
        // the sum of the contributions from an individual investor can't exceed this limit
        uint _maxIndividualLimit = phase == Phase.Seed ? SEED_MAX_INDIVIDUAL_LIMIT : MAX_INDIVIDUAL_LIMIT;

        // calculate the total individual contributions with the `_newAmount`
        uint _totalIndividualContribution = investments[_investor] + _newAmount;

        // calculate the total (collective) contributions with the `_newAmount`
        uint _totalContributed = totalInvested + _newAmount;

        // check the individual limit on the Seed and General phases
        if (phase == Phase.Seed || phase == Phase.General) {
            if (_totalIndividualContribution > _maxIndividualLimit) {
                revert ICO__IndividualMaxLimitReached();
            }
        }

        // ensure that the new investment don't exceed the total (collectively) maximum limit
        if (_totalContributed > _maxTotalLimit) {
            revert ICO__TotalMaxLimitReached();
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Throw when attempt to execute operations without authorization (not owner)
error SpaceCoin__Unauthorized();

/// @notice Throw when attempt to transfer an invalid amount
error SpaceCoin__InvalidAmount();

/// @notice Throw when provided address is invalid
error SpaceCoin__InvalidAddress();

contract SpaceCoin is ERC20 {
    uint256 constant public ONE_COIN = 10 ** 18;
    uint256 constant public TREASURY_SUPPLY = 350_000 * ONE_COIN;
    uint256 constant public ICO_SUPPLY = 150_000 * ONE_COIN;
    uint256 constant public TAX_PERCENTAGE = 2;
    bool public collectTax;
    address immutable public owner;
    address immutable public treasury;

    /**
     * @notice Emitted when the owner toggles the tax collection capability
     * @param collectTax Value that determines if collect tax is enabled/disabled
     */
    event ToggleTax(bool indexed collectTax);

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner {
        if (msg.sender != owner) {
            revert SpaceCoin__Unauthorized();
        }
        _;
    }

    constructor(address _owner, address _treasury, address _icoAddress) ERC20("SpaceCoin", "SPC") {
        // check to prevent being locked out by invalid addresses
        if (_isAddressZero(_owner) || _isAddressZero(_treasury) || _isAddressZero(_icoAddress)) {
            revert SpaceCoin__InvalidAddress();
        }

        owner = _owner;
        treasury = _treasury;
        _mint(_treasury, TREASURY_SUPPLY);
        _mint(_icoAddress, ICO_SUPPLY);
    }

    /**
     * @notice Toggle the collection of the `TAX_PERCENTAGE` for every transfer
     * @param _collectTax Boolean representing if the tax collection is enabled or not
     */
    function toggleTax(bool _collectTax) external onlyOwner {
        collectTax = _collectTax;
        emit ToggleTax(_collectTax);
    }

    /**
     * @notice Transfer a specific amount of tokens to another address
     * @param _to The address to receive the tokens
     * @param _amount The amount of tokens to send
     */
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        if (_amount <= 0) {
            revert SpaceCoin__InvalidAmount();
        }

        if (collectTax) {
            uint256 taxAmount = _amount * TAX_PERCENTAGE / 100;
            _amount -= taxAmount;
            _transfer(msg.sender, treasury, taxAmount);
        }

        _transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Check if an address is the address zero
     * @param _address Address to be checked
     * @return Bool that represents if the address is zero or not
     */
    function _isAddressZero(address _address) private pure returns (bool) {
        return _address == address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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