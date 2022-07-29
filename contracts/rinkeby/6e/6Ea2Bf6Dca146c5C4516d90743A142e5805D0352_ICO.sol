//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import {SpaceCoin} from "./SpaceCoin.sol";

contract ICO {
    /************************************************
     * Immutables and Constants
     ***********************************************/

    /// @notice Stores the address of the contract owner
    address public immutable owner;

    /// @notice Stores the goal of the ICO (in ETH)
    uint256 public constant GOAL = 30000 ether;

    /// @notice Stores price of ETH in SpaceToken
    uint256 public constant NUM_SPACECOIN_PER_ETH = 5;

    /************************************************
     * Enums
     ***********************************************/

    /// @notice Used to track the three stages an ICO goes through
    enum Phase {
        SEED,
        GENERAL,
        OPEN
    }

    /************************************************
     * State Variables
     ***********************************************/

    /// @notice Stores the state of the ICO
    /// @dev We assume ICOs cannot fail
    bool public is_funded;

    /// @notice Stores if the ICO has been paused
    bool public paused;

    /// @notice Stores the current phase
    Phase public phase;

    /// @notice Stores the SpaceCoin contract
    SpaceCoin public spaceCoin;

    /// @notice List of private investors who can contribute to phase seed
    /// @dev Use mapping for efficient lookups
    mapping(address => bool) public seedInvestorMap;

    /// @notice Store the amount of ETH (in decimals 18) contributed by addresses
    mapping(address => uint256) public amountContributed;

    /// @notice Total amount of funds for ICO in ETH
    uint256 public totalAmount;

    /************************************************
     * Events
     ***********************************************/

    /**
     * @notice Event to represent the ICO has been paused
     * @param currPhase The current phase
     */
    event PausedEvent(Phase currPhase);

    /**
     * @notice Event to represent the ICO has been resumed
     * @param currPhase The current phase
     */
    event ResumedEvent(Phase currPhase);

    /**
     * @notice Event to represent an ICO phase change
     * @param oldPhase The (now) previous phase
     * @param newPhase The (now) current phase
     */
    event PhaseChangeEvent(Phase oldPhase, Phase newPhase);

    /**
     * @notice Emitted when a contribution has been made
     * @param amount Amount of tokens to be contributed
     * @param user Address of the contributing wallet
     */
    event ContributionEvent(uint256 amount, address indexed user);

    /**
     * @notice Emitted when SpaceCoins are being withdrawn
     * @param amount Amount of SpaceCoins to be withdrawn
     * @param user Address of the contributing wallet
     */
    event WithdrawEvent(uint256 amount, address indexed user);

    /************************************************
     * Constructor and Initialization
     ***********************************************/

    /**
     * @notice Initialies the ICO contract
     */
    constructor(address _treasury) {
        // Deploy the `SpaceCoin` contract, which will mint token to this contract's address
        spaceCoin = new SpaceCoin(_treasury);

        // Transfer 350k to treasury since only 150k will be used for ICO
        /// @dev `SpaceCoin` does validation on _treasury already
        spaceCoin.transfer(_treasury, 350000 * 10**spaceCoin.decimals());

        // Set owner variable
        owner = msg.sender;

        // Default to seed phase
        phase = Phase.SEED;
    }

    /************************************************
     * Permissions and Roles
     ***********************************************/

    /// @notice Modifier that restricts to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner: not the owner");
        _;
    }

    /**
     * @notice Add investor to seed round (intended if not known at construction)
     * @dev This function can only be called by the owner in the seed phase
     * @param investor Adress to be added. Cannot be added twice
     */
    function grantSeedAccess(address investor) public onlyOwner {
        require(investor != address(0), "grantSeedAccess: empty address");
        require(phase == Phase.SEED, "grantSeedAccess: not in seed phase");
        require(
            !seedInvestorMap[investor],
            "grantSeedAccess: already have access"
        );
        seedInvestorMap[investor] = true;
    }

    /**
     * @notice Wrapper around `SpaceCoin.toggleTax`. Called only by owner.
     */
    function toggleTax() public onlyOwner {
      spaceCoin.toggleTax();
    }

    /**
     * @notice Owner can pause the ICO at anytime
     * @dev Emits an `PausedEvent` event
     */
    function pauseContributions() public onlyOwner {
        require(!paused, "pauseContributions: already paused");
        paused = true;
        emit PausedEvent(phase);
    }

    /**
     * @notice Owner can resume the ICO at anytime
     * @dev Emits an `ResumedEvent` event
     */
    function resumeContributions() public onlyOwner {
        require(paused, "resumeContributions: nothing to resume");
        paused = false;
        emit ResumedEvent(phase);
    }

    /**
     * @notice Owner can move phase forward
     * @dev This is the only way a phase moves forward. It does not move forward automatically.
     *      Emits a `PhaseChangeEvent` event
     */
    function movePhaseForward() public onlyOwner {
        require(phase != Phase.OPEN, "movePhaseForward: already in last phase");

        // Save old phase
        Phase oldPhase = phase;

        // Fetch new phase
        if (phase == Phase.SEED) {
            phase = Phase.GENERAL;
        } else {
            // must be Phase.GENERAL
            phase = Phase.OPEN;
        }

        emit PhaseChangeEvent(oldPhase, phase);
    }

    /************************************************
     * User Operations
     ***********************************************/

    /**
     * @notice Function for users to contribute funds to the ICO
     * @dev Emits a `ContributionEvent` event.
     */
    function contribute() public payable {
        require(msg.value > 0, "contribute: `msg.value` must be > 0");
        require(!paused, "contribute: ICO is currently paused");
        require(!is_funded, "contribute: ICO is already fully funded");

        // Check contribution respects contract constraints
        checkContribution(msg.sender, msg.value);

        // Track amount of contributions to user
        amountContributed[msg.sender] += msg.value;

        // Update the total amount of contributions
        totalAmount += msg.value;

        /// @dev `totalAmount` cannot exceed `GOAL` so suffices to check equality
        if (totalAmount == GOAL) {
            is_funded = true;
        }

        // Make the actual pull of ETH
        payable(msg.sender).transfer(msg.value);

        emit ContributionEvent(msg.value, msg.sender);
    }

    /**
     * @notice Users can withdraw SpaceCoin once Phase is open
     * @dev This is still allowed even if phase is pauseds
     */
    function withdraw() public {
        require(phase == Phase.OPEN, "withdraw: not in open phase");
        require(
            amountContributed[msg.sender] > 0,
            "withdraw: no contributions made"
        );

        // Compute amount of SpaceCoin to give
        uint256 amountWithdrawn = amountContributed[msg.sender] *
            NUM_SPACECOIN_PER_ETH;
        // Sanity check: cannot be larger than goal
        require(
          amountWithdrawn <= (GOAL * NUM_SPACECOIN_PER_ETH), 
          "amountWithdrawn: too large"
        );

        // Reset to zero so no double withdrawals
        /// @dev We do not update `totalAmount` which is needed to check
        //       if the ICO is fully funded. Users can withdraw before then
        amountContributed[msg.sender] = 0;

        // Transfer to sender
        spaceCoin.transfer(msg.sender, amountWithdrawn);

        emit WithdrawEvent(amountWithdrawn, msg.sender);
    }

    /************************************************
     * Helpers and Utilities
     ***********************************************/

    /**
     * @notice Check if contribution by an address is allowed
     * @dev Errors if contribution is not allowed
     * @param investor Address wishing to make the deposit
     * @param amount Amount the investor wishes to deposit
     */
    function checkContribution(address investor, uint256 amount) internal view {
        if (phase == Phase.SEED) {
            require(
                seedInvestorMap[investor],
                "checkContribution: not granted seed access"
            );
        }
        require(
            (totalAmount + amount) <= totalLimit(),
            "checkContribution: exceeds total limit"
        );
        (bool hasLimit, uint256 investorLimit) = individualLimit();
        if (hasLimit) {
            require(
                (amountContributed[investor] + amount) <= investorLimit,
                "checkContribution: exceeds individual limit for this phase"
            );
        }
    }

    /**
     * @notice Returns the total contribution limit depending on the current phase.
     *         In seed phase, contributions are limited to 15k ETH,
     *         In general and open phase, contributions are limited to 30k ETH (the goal)
     * @return amount limit amount in ETH
     */
    function totalLimit() internal view returns (uint256 amount) {
        amount = (phase == Phase.SEED) ? 15000 ether : 30000 ether;
    }

    /**
     * @notice Returns the individual contribution limit depending on the current phase.
     *         In seed phase, contributions are limited to 1.5k ETH.
     *         In general phase, contributions are limited to 1k ETH.
     *         In open phase, contributions are no longer limited
     * @return hasLimit True if a limit exists
     * @return amount limit amount in ETH. Zero if `hasLimit` is false
     */
    function individualLimit()
        internal
        view
        returns (bool hasLimit, uint256 amount)
    {
        if (phase == Phase.SEED) {
            hasLimit = true;
            amount = 1500 ether;
        } else if (phase == Phase.GENERAL) {
            hasLimit = true;
            amount = 1000 ether;
        } else {
            hasLimit = false;
            amount = 0 ether;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice SpaceCoin (SPC) token implementation
 */
contract SpaceCoin is ERC20("SpaceCoin", "SPC") {
    /// @notice Stores the address of the contract deployer
    /// @dev Call it `deployer` to distinguish from token owners
    address public immutable deployer;

    /// @notice Address of the treasury account
    address public immutable treasury;

    /// @notice Flag to control if tax is on or off (default off)
    bool public taxOn;

    /// @notice Tax percentage (decimals of 4)
    /// @dev For example, 20000 = 2 percent
    uint256 private constant TAX_AMOUNT = 20000;

    /// @notice Max total supply of 500k
    uint256 public constant MAX_SUPPLY = 500000 * 10**18;

    /**
     * @notice Event to represent a change in tax
     * @param taxOn If the tax is on or off
     */
    event ToggleTaxEvent(bool taxOn);

    /**
     * @notice Modifier that restricts to only the deployer
     */
    modifier onlyDeployer() {
        require(msg.sender == deployer, "onlyDeployer: not the deployer");
        _;
    }

    /**
     * @notice Initializes the SpaceCoin contract
     * @param _treasury Address for the treasury account. Cannot be empty
     */
    constructor(address _treasury) {
        require(_treasury != address(0), "constructor: empty treasury address");
        deployer = msg.sender;
        treasury = _treasury;

        // Mints maximum amount of tokens to deployer
        _mint(deployer, MAX_SUPPLY);
    }

    /**
     * @notice Wrapper around `ERC20._mint` but respects maximum supply bound.
     *         Prevents any future minting without burning
     * @dev Like `ERC20._mint`, emits a `Transfer` event
     * @param account Address to assign tokens to
     * @param amount Amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "_mint: exceeds max supply"
        );

        // Call parent implementation
        super._mint(account, amount);
    }

    /**
     * @notice Wrapper around `ERC20._transfer` but takes tax into account
     * @dev Used in both public `transfer` and `transferFrom` functions. Emits a `Transfer` emit
     * @param from Address sending tokens. Cannot be empty
     * @param to Address receiving tokens. Cannot be empty
     * @param amount Amount to transfer. The `from` address must have at least this amount
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Defer to `_transfer` for other checks
        require(amount > 0, "_transfer: `amount` must be non-positive");
        if (taxOn) {
            // If tax, pass 98% to address `to` and 2% to treasury
            /// @dev Divide by 6 because decimals 4 plus 2 for percentages
            uint256 taxAmount = (TAX_AMOUNT * amount) / 10**6;
            require(
                taxAmount < amount,
                "_transfer: tax must be less than `amount`"
            );
            uint256 transferAmount = amount - taxAmount;
            super._transfer(from, to, transferAmount);
            super._transfer(from, treasury, taxAmount);
        } else {
            // If no tax, call parent with default args
            super._transfer(from, to, amount);
        }
    }

    /**
     * @notice Turn the tax on or off. Can be called only by deployer
     */
    function toggleTax() public onlyDeployer {
        taxOn = !taxOn;
        emit ToggleTaxEvent(taxOn);
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