//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Ico.sol";

contract SpaceCoin is ERC20 {
  // SpaceCoin contract owner
  // how to not make this public (used in spacecoin.text.ts)
  address public immutable owner;

  // Address of the treasury
  // how to not make this public (used in spacecoin.text.ts)
  address public immutable treasury;

  // Address of the deployed ICO contract
  address public immutable icoAddress;

  // Whether the 2% transfer tax is currently enabled (can be toggled by owner)
  bool public transferTaxOn;

  // Events
  event ICOCreated(address icoAddress);
  event TransferTaxTurnedOn();
  event TransferTaxTurnedOff();

  // Custom errors
  error NonOwnerNotAllowed();

  // Modifier helpers
  modifier onlyOwnerAllowed() {
    if (msg.sender != owner) {
      revert NonOwnerNotAllowed();
    }
    _;
  }

  /**
   * @dev Project constructor
   * @param _owner Address of the owner of both the SpaceCoin and ICO contracts
   * @param _treasury Address of the token contract's treasury account
   */
  constructor(
    address _owner,
    address _treasury,
    address[] memory allowlist
  ) ERC20("SpaceCoin", "SPC") {
    owner = _owner;
    treasury = _treasury;
    ICO ico = new ICO(_owner, this, allowlist);
    icoAddress = address(ico);

    // TODO: figure out variables
    // Mint tokens
    _mint(icoAddress, 150000 ether);
    _mint(treasury, 350000 ether);

    emit ICOCreated(address(ico));
  }

  /**
   * @dev Toggles the transferTaxOn boolean variable
   */
  function toggleTransferTax() public {
    require(msg.sender == owner, "Only owner can toggle transfer tax");
    transferTaxOn = !transferTaxOn;
    if (transferTaxOn) emit TransferTaxTurnedOn();
    else if (!transferTaxOn) emit TransferTaxTurnedOff();
  }

  /**
   * @dev Overrides ERC20's internal _transfer function
   * to apply a 2% tax on any calls to transfer() or transferFrom()
   * @param from Account to transfer tokens from
   * @param to Account to transfer tokens to
   * @param amount Amount of tokens to transfer to recipient
   */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    uint256 nettAmount;
    if (transferTaxOn) {
      uint256 tax = amount / 50;
      nettAmount = amount - tax;
      super._transfer(from, treasury, tax);
    } else {
      nettAmount = amount;
    }
    return super._transfer(from, to, nettAmount);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./SpaceCoin.sol";

contract ICO {
  enum Phase {
    SEED,
    GENERAL,
    OPEN
  }

  // Exchange rate 5 SPC to 1 ETH
  uint256 constant SPC_PER_ETH = 5;

  // ICO contribution limits for Phase Seed
  uint256 constant SEED_TOTAL_CONTRIBUTION_LIMIT = 15000 ether;
  uint256 constant SEED_INDIVIDUAL_CONTRIBUTION_LIMIT = 1500 ether;

  // ICO contribution limits for Phase General and Phase Open
  uint256 constant PUBLIC_TOTAL_CONTRIBUTION_LIMIT = 30000 ether;
  uint256 constant GENERAL_INDIVIDUAL_CONTRIBUTION_LIMIT = 1000 ether;

  // ICO contract owner
  // make internal
  address public immutable owner;

  // SpaceCoin contract
  SpaceCoin private immutable spaceCoin;

  // Current ICO phase
  Phase public phase;

  // Whether fundraising is currently enabled (can be toggled by owner)
  bool public fundraisingEnabled;

  // Whether token redemption is currently enabled (can be toggled by owner)
  bool public tokenRedemptionEnabled;

  // Current phase's total contribution limit
  uint256 public totalContributionLimit;

  // Current phase's individual contribution limit (ignored in Phase Open)
  uint256 public individualContributionLimit;

  // Allowlist of contributors for Phase Seed
  mapping(address => bool) private allowlist;

  // Total contributions (in units of Wei)
  uint256 internal totalContributions;

  // Mapping from contributor address to total contributed amount (in units of Wei)
  mapping(address => uint256) internal totalContributionsOf;

  // Mapping of contributor address to ETH contribution balance (in units of Wei)
  // that remains unconverted to SPC tokens
  mapping(address => uint256) internal ethBalanceOf;

  // Events
  event PhaseStarted(Phase phase);
  event FundraisingStatusChanged(bool active);
  event TokenRedemptionStatusChanged(bool active);
  event ContributionSuccessful(address contributor, uint256 amount);
  event TokensRedeemed(address recipient, uint256 numTokens);

  // Custom errors
  error NonOwnerNotAllowed();
  error ExceededIndividualLimit(
    address contributor,
    uint256 requested,
    uint256 available
  );
  error ExceededTotalLimit(
    address contributor,
    uint256 requested,
    uint256 available
  );

  // Modifier helpers
  modifier onlyOwnerAllowed() {
    if (msg.sender != owner) {
      revert NonOwnerNotAllowed();
    }
    _;
  }

  constructor(
    address _owner,
    SpaceCoin _spaceCoin,
    address[] memory _allowlist
  ) {
    owner = _owner;
    spaceCoin = _spaceCoin;
    fundraisingEnabled = true;
    totalContributionLimit = SEED_TOTAL_CONTRIBUTION_LIMIT;
    individualContributionLimit = SEED_INDIVIDUAL_CONTRIBUTION_LIMIT;

    for (uint256 i = 0; i < _allowlist.length; i++) {
      allowlist[_allowlist[i]] = true;
    }
  }

  /**
   * @dev Moves the ICO to the next phase
   */
  function progressPhase() public onlyOwnerAllowed {
    require(phase != Phase.OPEN, "Already in the final phase");

    if (phase == Phase.SEED) {
      // Progress from Phase Seed to Phase General
      phase = Phase.GENERAL;
      totalContributionLimit = PUBLIC_TOTAL_CONTRIBUTION_LIMIT;
      individualContributionLimit = GENERAL_INDIVIDUAL_CONTRIBUTION_LIMIT;
    } else if (phase == Phase.GENERAL) {
      // Progress from Phase General to Phase Open
      phase = Phase.OPEN;
      tokenRedemptionEnabled = true;
    }

    emit PhaseStarted(phase);
  }

  /**
   * @dev Toggle whether fundraising is enabled
   */
  function toggleFundraisingStatus() public onlyOwnerAllowed {
    fundraisingEnabled = !fundraisingEnabled;
    emit FundraisingStatusChanged(fundraisingEnabled);
  }

  /**
   * @dev Toggle whether token redemption is enabled
   */
  function toggleTokenRedemptionStatus() public onlyOwnerAllowed {
    require(phase == Phase.OPEN, "Token redemption only allowed in Phase Open");
    tokenRedemptionEnabled = !tokenRedemptionEnabled;
    emit TokenRedemptionStatusChanged(tokenRedemptionEnabled);
  }

  /**
   * @dev Contribute to the ICO
   */
  function contribute() public payable {
    require(fundraisingEnabled, "Fundraising not enabled");
    require(msg.value > 0, "Contributions must be above 0");

    if (totalContributions + msg.value > totalContributionLimit) {
      revert ExceededTotalLimit(
        msg.sender,
        msg.value,
        totalContributionLimit - totalContributions
      );
    }

    if (
      phase != Phase.OPEN &&
      totalContributionsOf[msg.sender] + msg.value > individualContributionLimit
    ) {
      revert ExceededIndividualLimit(
        msg.sender,
        msg.value,
        individualContributionLimit - totalContributionsOf[msg.sender]
      );
    }

    if (phase == Phase.SEED) {
      require(allowlist[msg.sender], "Contributor not in allowlist");
    }

    totalContributions += msg.value;
    totalContributionsOf[msg.sender] =
      totalContributionsOf[msg.sender] +
      msg.value;
    ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender] + msg.value;

    emit ContributionSuccessful(msg.sender, msg.value);
  }

  /**
   * @dev Redeem SPC tokens based on previous ETH contributions
   *      (only available during Phase Open)
   */
  function redeem() public {
    require(tokenRedemptionEnabled, "Token redemption not enabled");

    uint256 tokensDue = ethBalanceOf[msg.sender] * SPC_PER_ETH;
    require(tokensDue > 0, "No tokens to redeem");

    // Reset ETH balance of the contributor since all ETH is already
    // redeemed for SPC
    ethBalanceOf[msg.sender] = 0;

    spaceCoin.transfer(msg.sender, tokensDue);

    emit TokensRedeemed(msg.sender, tokensDue);
  }

  /**
   * @dev Returns the number of SPCs earned by the caller thus far
   */
  function spcEarned() public view returns (uint256) {
    return totalContributionsOf[msg.sender] * SPC_PER_ETH;
  }

  /**
   * @dev Returns the outstanding SPCs the caller can redeem
   */
  function spcRedeemable() public view returns (uint256) {
    return ethBalanceOf[msg.sender] * SPC_PER_ETH;
  }

  /**
   * @dev Returns the number of SPCs available for the caller to purchase
   *      in the current phase of the ICO
   */
  function spcAvailableToBuy() public view returns (uint256) {
    if (phase == Phase.SEED && !allowlist[msg.sender]) return 0;

    uint256 individualEthQuotaRemaining = individualContributionLimit -
      totalContributionsOf[msg.sender];
    uint256 totalEthQuotaRemaining = totalContributionLimit -
      totalContributions;

    if (totalEthQuotaRemaining > individualEthQuotaRemaining) {
      return individualEthQuotaRemaining * SPC_PER_ETH;
    } else {
      return totalEthQuotaRemaining * SPC_PER_ETH;
    }
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