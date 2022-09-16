//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";

/// @title ICO
/// @author Erik Reppel
contract ICO {
    // Constructor initialized state
    address public owner;
    SpaceCoin public spaceCoin;
    mapping(address => bool) public allowList;

    // Constants
    uint256 immutable MAX_INT = 2**256 - 1;
    uint256 immutable SPC_PER_ETH = 5;
    uint256 public immutable maxTotalContributions = 30_000 ether;
    mapping(Phase => PhaseParameters) public phaseParameters;

    // Mutable state
    bool public contributingPaused;
    bool public redemptionsPaused;
    Phase public currentPhase = Phase.Seed;
    uint256 public totalContributed;
    uint256 public unredeemedContributions;
    mapping(address => uint256) public contributions;

    // Types

    enum Phase {
        Seed,
        General,
        Open
    }

    enum AllowedContributors {
        AllowList,
        Anyone
    }

    struct PhaseParameters {
        AllowedContributors allowedContributors;
        uint256 maxIndividualContribution;
        uint256 maxPhaseContribution;
    }

    // Errors
    error AllowListEmpty();
    error AlreadyInOpenPhase();
    error OnlyOwner();
    error NotAllowedDuringPhase(address);
    error NoContributionsPaused();
    error ContributionMoreThanIndividualLimit(uint256);
    error ContributionMoreThanPhaseLimit(uint256);
    error NoRedemptionsPaused();
    error NoRedemptions();
    error NoFunds();
    error RedemptionFailed(
        address contributor,
        uint256 ethContributed,
        uint256 spcRedeemed
    );

    // Events
    event PhaseAdvanced(Phase);
    event ContributionsSetPaused();
    event ContributionsUnsetPaused();
    event ContributionMade(address indexed contributor, uint256 amount);
    event RedemptionsUnsetPaused();
    event RedemptionsSetPaused();
    event RedemptionSuceeded(
        address contributor,
        uint256 ethContributed,
        uint256 spcRedeemed
    );

    constructor(address _treasury, address[] memory _allowList) {
        if (_allowList.length == 0) revert AllowListEmpty();

        owner = msg.sender;

        // set mapping addresses to true, since all other addresses will return type default false
        for (uint256 i = 0; i < _allowList.length; ++i) {
            allowList[_allowList[i]] = true;
        }

        // Deploy the token
        spaceCoin = new SpaceCoin(msg.sender, _treasury, address(this));

        // Cannot initialize mappings as constants, set parameters for each phase
        phaseParameters[Phase.Seed] = PhaseParameters({
            allowedContributors: AllowedContributors.AllowList,
            maxIndividualContribution: 1500 ether,
            maxPhaseContribution: 15_000 ether
        });

        phaseParameters[Phase.General] = PhaseParameters({
            allowedContributors: AllowedContributors.Anyone,
            maxIndividualContribution: 1000 ether,
            maxPhaseContribution: maxTotalContributions
        });

        phaseParameters[Phase.Open] = PhaseParameters({
            allowedContributors: AllowedContributors.Anyone,
            maxIndividualContribution: MAX_INT,
            maxPhaseContribution: maxTotalContributions
        });
    }

    function advancePhase() external onlyOwner {
        if (currentPhase == Phase.Seed) {
            currentPhase = Phase.General;
        } else if (currentPhase == Phase.General) {
            currentPhase = Phase.Open;
        } else {
            revert AlreadyInOpenPhase();
        }
        emit PhaseAdvanced(currentPhase);
    }

    function pauseContributions() external onlyOwner {
        contributingPaused = true;
        emit ContributionsSetPaused();
    }

    function unpauseContributions() external onlyOwner {
        contributingPaused = false;
        emit ContributionsUnsetPaused();
    }

    function contribute()
        external
        payable
        contributionsEnabled
        onlyAllowContributorForPhase
    {
        PhaseParameters memory rules = phaseParameters[currentPhase];
        uint256 amount = msg.value;

        if (
            contributions[msg.sender] + amount > rules.maxIndividualContribution
        ) revert ContributionMoreThanIndividualLimit(amount);

        // Note: phase limit is at max the maxTotalContributions, no need to check maxTotalContributions seperately
        if (totalContributed + amount > rules.maxPhaseContribution)
            revert ContributionMoreThanPhaseLimit(amount);

        contributions[msg.sender] += amount;
        totalContributed += amount;
        unredeemedContributions += amount;
    }

    function pauseRedemptions() external onlyOwner {
        redemptionsPaused = true;
        emit RedemptionsSetPaused();
    }

    function unpauseRedemptions() external onlyOwner {
        redemptionsPaused = false;
        emit RedemptionsUnsetPaused();
    }

    function redeem() external {
        if (redemptionsPaused) revert NoRedemptionsPaused();
        if (currentPhase != Phase.Open) revert NoRedemptions();
        if (contributions[msg.sender] == 0) revert NoFunds();

        uint256 ethContributed = contributions[msg.sender];
        ///  @dev This is safe because we know SPC and ETH have the same number of decimals
        uint256 amountSPC = ethContributed * SPC_PER_ETH;

        unredeemedContributions -= ethContributed;
        contributions[msg.sender] = 0;

        bool result = spaceCoin.transfer(msg.sender, amountSPC);
        emit RedemptionSuceeded(msg.sender, ethContributed, amountSPC);

        if (!result)
            revert RedemptionFailed(msg.sender, ethContributed, amountSPC);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyAllowContributorForPhase() {
        AllowedContributors currentlyAllowed = phaseParameters[currentPhase]
            .allowedContributors;
        // if we're not in open or general, they gotta be on the allow list
        if (
            currentlyAllowed == AllowedContributors.AllowList &&
            !allowList[msg.sender]
        ) {
            revert NotAllowedDuringPhase(msg.sender);
        } else {
            _;
        }
    }

    modifier contributionsEnabled() {
        if (contributingPaused) revert NoContributionsPaused();
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    address public owner;
    address public treasury;
    address icoAddress;
    bool public taxEnabled = true;
    uint256 public immutable taxBPS = 200;
    uint256 private immutable BPSPerPct = 10_000;

    event TaxEnabled();
    event TaxDisabled();

    error TransferAmountTooSmall(uint256);
    error OnlyOwner();
    error TaxAlreadyEnabled();
    error TaxAlreadyDisabled();

    constructor(
        address _owner,
        address _treasury,
        address _icoAddress
    ) ERC20("SpaceCoin", "SPC") {
        owner = _owner;
        treasury = _treasury;
        icoAddress = _icoAddress;

        // @notice: we're performing all mints in the constructor such that totalSupply will equal 500_00
        // this prevents needing to override totalSupply()

        _mint(_icoAddress, 150_000 * (10**decimals()));
        _mint(treasury, 350_000 * (10**decimals()));
    }

    function disableTax() public {
        if (msg.sender != owner) revert OnlyOwner();
        if (taxEnabled == false) revert TaxAlreadyDisabled();
        taxEnabled = false;
        emit TaxDisabled();
    }

    function enableTax() public {
        if (msg.sender != owner) revert OnlyOwner();
        if (taxEnabled == true) revert TaxAlreadyEnabled();
        taxEnabled = true;
        emit TaxEnabled();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount < BPSPerPct) revert TransferAmountTooSmall(amount);

        /// @notice: don't tax redemptions from the ICO address, its supposed to
        // "release SpaceCoin tokens at an exchange rate of 5 SPC to 1 ETH."
        if (!taxEnabled || from == icoAddress) {
            super._transfer(from, to, amount);
        } else {
            uint256 fee = (amount * taxBPS) / BPSPerPct;
            uint256 remaining = amount - fee;
            super._transfer(from, treasury, fee);
            super._transfer(from, to, remaining);
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