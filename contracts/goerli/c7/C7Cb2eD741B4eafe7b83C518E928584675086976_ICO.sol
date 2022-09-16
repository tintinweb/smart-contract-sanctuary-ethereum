//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";

interface ISpaceCoin {
    function mint(address to, uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @dev An ICO contract that allows users to contribute ETH in return for being
 *      able to redeem the ETH for the ICO's token, SpaceCoin (SPC) at a 5-to-1
 *      ratio.  ICO has three phases with, users may withdraw their SPC in the
 *      third and final phase.
 */
contract ICO {
    /**
     *
     * Errors and Events ==========================================================================
     *
     */

    error AlreadyWhitelisted();
    error CannotWhitelistZeroAddress();
    error ContributionsPaused();
    error ContributorsOnly();
    error ExceedsAccountLimit(
        uint256 contribution,
        uint256 accountTotal,
        uint256 accountLimit
    );
    error ExceedsPhaseLimit(
        uint256 contribution,
        uint256 totalRaised,
        uint256 phaseLimit
    );
    error IcoIsPaused();
    error IcoNotPaused();
    error IllegalPhaseTransition();
    error InvalidPhase(Phase current, Phase required);
    error InsufficientContribution();
    error PhaseLimitMet();
    error SeedPhaseExpired();
    error Unauthorized();

    event AddressWhitelisted(address indexed);
    event ClaimProcessed(address indexed account, uint256 amount);
    event ContributionReceived(
        address indexed account,
        Phase indexed phase,
        uint256 amount,
        uint256 accountTotal,
        uint256 totalRaised
    );
    event Paused();
    event PhaseAdvanced(Phase newPhase);
    event Unpaused();

    /**
     *
     * Contract types, constants and variables ====================================================
     *
     */

    enum Phase {
        SEED,
        GENERAL,
        OPEN
    }

    uint8 public constant SPC_PER_WEI = 5;
    uint256 public constant FUNDING_GOAL = 30_000 ether;
    uint256 public constant UINT_MAX = 2**256 - 1;

    address public immutable owner;
    address public immutable spaceCoinAddress;

    bool public paused;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelisted;

    uint256 public totalRaised;
    uint256[] public accountLimits = [1500 ether, 1000 ether, UINT_MAX];
    uint256[] public phaseLimits = [15000 ether, FUNDING_GOAL, FUNDING_GOAL];

    Phase public phase;

    /**
     *
     * Modifiers ==================================================================================
     *
     */

    modifier notPaused() {
        if (paused) revert IcoIsPaused();
        _;
    }

    modifier onlyContributor() {
        if (0 == contributions[msg.sender]) revert ContributorsOnly();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier requiresPhase(Phase _phase) {
        if (phase != _phase) revert InvalidPhase(phase, _phase);
        _;
    }

    /**
     *
     * Constructor ================================================================================
     *
     */

    /**
     * @dev Create an instance of the ICO contract
     *
     * @param _treasuryAddress The address which will recieve all SPC beyond what's available
     *        for purchase in the ICO as well as all SPC claimed through taxation
     */
    constructor(address _treasuryAddress) {
        // We'll need a local reference to treasury address in future
        // projects but until then we do not so I'm omitting it
        owner = msg.sender;
        phase = Phase.SEED;
        spaceCoinAddress = address(
            new SpaceCoin(msg.sender, address(this), _treasuryAddress)
        );
        // Mint ICO participant redemption SPC
        ISpaceCoin(spaceCoinAddress).mint(
            address(this),
            SPC_PER_WEI * FUNDING_GOAL
        );
        // Mint treasury funds
        ISpaceCoin(spaceCoinAddress).mint(_treasuryAddress, 350_000 * 1e18);
    }

    /**
     *
     * Public/external functions ==================================================================
     *
     */

    /**
     * @dev Advance the ICO to the next phase
     */
    function advancePhase() external onlyOwner {
        if (phase == Phase.OPEN) {
            revert IllegalPhaseTransition();
        }
        phase = phase == Phase.SEED ? Phase.GENERAL : Phase.OPEN;
        emit PhaseAdvanced(phase);
    }

    /**
     * @dev Claim SPC commensurate to the amount of ETH contributed in any/all of the three
     *      ICO phases. May only be called during the OPEN phase.
     */
    function claim()
        external
        onlyContributor
        notPaused
        requiresPhase(Phase.OPEN)
    {
        uint256 claimAmount = SPC_PER_WEI * contributions[msg.sender];
        contributions[msg.sender] = 0;
        // The OZ ERC20 implementation throws on error, otherwise always
        // returns `true` so I'm not bothering to check retval here
        ISpaceCoin(spaceCoinAddress).transfer(msg.sender, claimAmount);
        emit ClaimProcessed(msg.sender, claimAmount);
    }

    /**
     * @dev Contribute ETH to the ICO
     */
    function contribute() external payable notPaused {
        if (msg.value == 0) {
            revert InsufficientContribution();
        }
        if (phase == Phase.SEED && !whitelisted[msg.sender]) {
            revert Unauthorized();
        }
        // Does contribution put account over their limit?
        if (
            contributions[msg.sender] + msg.value >
            accountLimits[uint256(phase)]
        ) {
            revert ExceedsAccountLimit(
                msg.value,
                contributions[msg.sender],
                accountLimits[uint256(phase)]
            );
        }
        // Does contribution exceed the current phase limit?
        if (totalRaised + msg.value > phaseLimits[uint256(phase)]) {
            revert ExceedsPhaseLimit(
                msg.value,
                totalRaised,
                phaseLimits[uint256(phase)]
            );
        }
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit ContributionReceived(
            msg.sender,
            phase,
            msg.value,
            contributions[msg.sender],
            totalRaised
        );
    }

    /**
     * @dev Pause the ICO, which disables both contributions and claims
     */
    function pause() external onlyOwner notPaused {
        if (paused) revert IcoIsPaused();
        paused = true;
        emit Paused();
    }

    /**
     * @dev Unpause the ICO
     */
    function unpause() external onlyOwner {
        if (!paused) revert IcoNotPaused();
        paused = false;
        emit Unpaused();
    }

    /**
     * @dev Whitelist an address, making it eligible to contribute during the "Seed" phase
     */
    function whitelist(address _address)
        external
        onlyOwner
        requiresPhase(Phase.SEED)
    {
        if (_address == address(0)) {
            revert CannotWhitelistZeroAddress();
        }
        if (whitelisted[_address]) {
            revert AlreadyWhitelisted();
        }
        whitelisted[_address] = true;
        emit AddressWhitelisted(_address);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev A custom ERC-20 token being sold in the ICO
 */
contract SpaceCoin is ERC20 {
    /**
     *
     * Errors and Events ==========================================================================
     *
     */

    error ExceedsMaxSupply(
        uint256 maxSupply,
        uint256 totalSupply,
        uint256 amount
    );
    error TaxationSettingAlreadyApplied();
    error Unauthorized();

    event TaxationUpdated(bool taxationEnabled);

    /**
     *
     * Contract types, constants and variables ====================================================
     *
     */

    uint256 public constant MAX_SUPPLY = 500000 * 1e18;
    uint8 public constant TRANSFER_TAX_PERCENT = 2; // 2%

    address public immutable icoContract;
    address public immutable owner;
    address public immutable treasuryAddress;

    bool public applyingTax;

    /**
     *
     * Modifiers ==================================================================================
     *
     */

    modifier onlyIco() {
        if (msg.sender != icoContract) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    /**
     *
     * Constructor ================================================================================
     *
     */

    /**
     * @dev Create SpaceCoin
     * 
     * @param _owner The contract owner
     * @param _icoContract The ICO contract address
     * @param _treasuryAddress The address that this contract will send taxed SPC to
     */
    constructor(
        address _owner,
        address _icoContract,
        address _treasuryAddress
    ) ERC20("SpaceCoin", "SPC") {
        owner = _owner;
        icoContract = _icoContract;
        treasuryAddress = _treasuryAddress;
    }

    /**
     *
     * Public/external functions ==================================================================
     *
     */

    /**
     * @dev Enable or disable taxation of SPC transfers
     * 
     * @param enabled Boolean indicating whether to enable taxation (true) or disable it (false)
     */
    function applyTax(bool enabled) external onlyOwner {
        if (enabled == applyingTax) revert TaxationSettingAlreadyApplied();
        // Update
        applyingTax = enabled;
        emit TaxationUpdated(enabled);
    }

    /**
     * @dev Mint SPC tokens
     * 
     * @param to Address of token recipient
     * @param amount Amount of SPC to mint
     */
    function mint(address to, uint256 amount) external onlyIco {
        // While it's true that we control the calls to this function,
        // I'm retaining this check as a safeguard. That being said it
        // is not testable via hardhat as far as I can determine
        if (amount + totalSupply() > MAX_SUPPLY)
            revert ExceedsMaxSupply(MAX_SUPPLY, totalSupply(), amount);
        _mint(to, amount);
    }

    /**
     *
     * Private/interal functions ==================================================================
     *
     */

    /**
     * @dev Override ERC20's internal _transfer function in order to apply taxation
     *      on all SPC transfers (iff that feature is enabled)
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!applyingTax) {
            super._transfer(from, to, amount);
        } else {
            // For contributions < 50 wei this value is 0, which is ok
            uint256 tax = (amount * TRANSFER_TAX_PERCENT) / 100;
            super._transfer(from, treasuryAddress, tax);
            super._transfer(from, to, amount - tax);
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