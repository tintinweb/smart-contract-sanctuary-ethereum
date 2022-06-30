//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./SpaceCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** @notice Event emitted when a investor tries to send more than the ETH to reach the ICO Phase Target.
 *  The available amount should be calculated from: targetAmount - raisedAmount (0 if the result is negative).
 *  @param raisedAmount Amount of ETH raised by the contract so far.
 *  @param targetAmount Target amount to be reaches.
 */
error PhaseTargetReached(uint256 raisedAmount, uint256 targetAmount);

/** @notice Event emitted when a investor tries to send more than the ETH to reach the Individual Phase Target.
 *  The available amount should be calculated from: targetAmount - raisedAmount (0 if the result is negative).
 *  @param raisedAmount Amount of ETH raised by the contract so far.
 *  @param targetAmount Target amount to be reaches.
 */
error IndividualTargetReached(uint256 raisedAmount, uint256 targetAmount);

/// @title ICO Project
/// @author Agustin Bravo
/// @notice Contract for fundraising ICO Project, token deployed within this contracts constructor.
contract Sale is Ownable {
    enum Phase {
        seed,
        general,
        open
    }

    /// Constant declarations of utils used inside contract.
    uint256 constant TARGET_GOAL = 30_000 ether;
    uint256 constant SEED_GOAL = 15_000 ether;
    uint256 constant INDIVIDUAL_SEED_CONTRIB = 1_500 ether;
    uint256 constant INDVIDUAL_GRAL_CONTRIB = 1_000 ether;
    uint256 constant TOKEN_RATE = 5;

    /// ERC20 Token deployed and fundraised by ICO.
    SpaceCoin public spaceCoinToken;

    /// Current phase of the ICO.
    Phase public SalePhase;

    /**
     * @dev Owner can pause the fundraising of the ICO:
     * True: Paused, contribute function not enabled.
     * False: Unpaused or normal behavior.
     */
    bool public pauseActive;

    /// Array of Whitelisted addresses setted in the constroctur.
    address[] public whitelisted;

    /// Individual contributions/sales per address in ETH.
    mapping(address => uint256) public contributions;

    /**
     *  @notice Used to save tokens allocations if ICO Phase is different from open.
     *  If Phase.open is active release tokens within the contribution function call.
     *  This variable gets zeroed once the tokens are redeemed.
     */
    mapping(address => uint256) public pendingTokens;

    /// Total funds raised in contract from all phases and all investors.
    uint256 public totalContributionsRaised;

    /// Total funds not withdrawn available to withdraw.
    uint256 public availableFunds;

    /// @notice Event emmited once a contribution has been made regardless of the phase.
    /// @param contributor Address of the investor calling the function.
    /// @param amount Amount of ETH invested.
    event Contribution(address indexed contributor, uint256 amount);

    /**
     *  @notice Event emmited:
     *  - Once a contribution has been made in phase Open
     *  - Or once an investor called redeemTokens after contributing in a different Phase.
     *  @param contributor Address of the investor calling the function.
     *  @param tokenAmount Amount of ETH invested.
     */
    event TokensRedeemed(address indexed contributor, uint256 tokenAmount);

    /**
     *  @notice Current phase of the ICO:
     *   -  Phase.seed (0).
     *   -  Phase.general (1).
     *   -  Phase.open (2).
     *  @param newPhase New phase advanced by the owner
     */
    event AdvancePhase(Phase newPhase);

    /// Event emmited when owner calls Pause function, this disables fundraising contributions.
    event Pause();

    /// Event emmited when owner calls Unpause function, this enables fundraising contributions again.
    event Unpause();

    /// Event emmited when owner withdraws funds to an external address. Only in the open phase.
    event Withdrawn(address indexed to, uint256 amount);
    /// @notice Initialization of contract with owner and whitelisted addresses.
    /// @dev The constructor deploys the SpaceCoin ERC20 Token initialazing its own constructor.
    /// @param _treasury Address of EOA that holds the treasury tokens and collect tax fees.
    /// @param _whitelisted Array of addresses whitelisted to contribute in Phase Seed.
    constructor(address _treasury, address[] memory _whitelisted, address _multiSig) {
        whitelisted = _whitelisted;
        spaceCoinToken = new SpaceCoin(_treasury, address(this));
        spaceCoinToken.transferOwnership(_multiSig);
        transferOwnership(_multiSig);
    }



    /// Modifier that verifies that the contract is not paused.
    modifier whenNotPaused() {
        require(!pauseActive, "SALE_PAUSED");
        _;
    }

    /**
     *  @notice Function used to participate in ICO. Sending ETH to this function will grant you SpaceCoin Tokens:
     *      - Phase Seed: Only whitelisted addresses can invest and their tokens will be redeem after the phase advance to Open
     *      (You will need to call redeem tokens)
     *      - Phase General: Is open for all users to invest and their tokens will be redeem after the phase advance to Open
     *      (You will need to call redeem tokens)
     *      - Phase Open: Any user can invest and will get their tokens within the same transaction.
     *  This function is only available to use when pauseActive is false (Owner can pause the contract)
     */
    function contribute() public payable whenNotPaused {
        require(msg.value > 0, "NO_ETH_SENT");
        if (SalePhase == Phase.seed) {
            require(checkWhitelisted(), "NOT_WHITELISTED");
        }
        if (totalContributionsRaised + msg.value > checkCurrentPhaseMax()) {
            revert PhaseTargetReached({
                raisedAmount: totalContributionsRaised,
                targetAmount: checkCurrentPhaseMax()
            });
        }
        if (
            contributions[msg.sender] + msg.value > checkCurrentIndividualMax()
        ) {
            revert IndividualTargetReached({
                raisedAmount: contributions[msg.sender],
                targetAmount: checkCurrentIndividualMax()
            });
        }
        availableFunds += msg.value;
        totalContributionsRaised += msg.value;
        contributions[msg.sender] += msg.value;
        uint256 amountOfTokens = (msg.value * TOKEN_RATE);
        pendingTokens[msg.sender] += amountOfTokens;
        if (SalePhase == Phase.open) {
            redeemTokens();
        }
        emit Contribution(msg.sender, msg.value);
    }

    /// @notice Throught this function Seed and General phase contributors can redeem their pendint tokens.
    /// @dev In phase Open this function gets called inside contribute function.
    function redeemTokens() public {
        require(SalePhase == Phase.open, "NOT_REDEEMABLE_YET");
        require(pendingTokens[msg.sender] > 0, "NO_PENDING_TOKENS");
        spaceCoinToken.transfer(msg.sender, pendingTokens[msg.sender]);
        emit TokensRedeemed(msg.sender, pendingTokens[msg.sender]);
        pendingTokens[msg.sender] = 0;
    }

    /// @dev Internal function used to loop throughth the whitelisted addresses
    /// @return True if the msg.sender is whitelisted. False if not
    function checkWhitelisted() public view returns (bool) {
        uint256 whitelistLength = whitelisted.length;
        for (uint256 i = 0; i < whitelistLength; ++i) {
            if (whitelisted[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /// @notice Function use to withdraw funds when the ICO reaches OPEN phase. Only Owner can call this function.
    /// @param to Destiny address to receive the withdrawn funds
    /// @param amount Desired amount of eth to withdraw
    function withdrawFunds(address to, uint256 amount) external onlyOwner {
        require(SalePhase == Phase.open, "ONLY_OPEN_PHASE");
        require(amount <= availableFunds, "NOT_ENOUGHT_FUNDS");
        availableFunds -= amount;
        emit Withdrawn(to, amount);
        (bool success, ) = to.call{value: amount}("");
        require(success, "TRANSFER_FAILED");
    }

    /// @notice Owner can advance Phase whenever he wants, only fordward and one phase per call.
    /// @dev Function will revert if the last phase is already active.
    /// @param expectedCurrentPhase Expected current phase used to avoid double calls and advance to an undesired phase.
    function advancePhase(Phase expectedCurrentPhase) external onlyOwner {
        require(expectedCurrentPhase == SalePhase, "INVALID_PHASE_EXPECTED");
        require(SalePhase != Phase.open, "LAST_PHASE_REACHED");
        SalePhase = Phase(uint8(SalePhase) + 1);
        emit AdvancePhase(SalePhase);
    }

    /// Owner can Pause the contributions by calling this function.
    function pauseSale() external onlyOwner {
        require(!pauseActive, "ALREADY_PAUSED");
        pauseActive = true;
        emit Pause();
    }

    /// Owner can Unpause the contributions by calling this function.
    function unpauseSale() external onlyOwner {
        require(pauseActive, "ALREADY_UNPAUSED");
        pauseActive = false;
        emit Unpause();
    }

    /// @dev Internal function used to check current ICO phase maximun contributions.
    /// @return Returns the constant threshold of the current phase.
    function checkCurrentPhaseMax() internal view returns (uint256) {
        if (SalePhase == Phase.seed) {
            return SEED_GOAL;
        } else {
            return TARGET_GOAL;
        }
    }

    /// @dev Internal function used to check current phase individual maximun contributions.
    /// @return Returns the constant of individual threshold of the current phase.
    function checkCurrentIndividualMax() internal view returns (uint256) {
        if (SalePhase == Phase.seed) {
            return INDIVIDUAL_SEED_CONTRIB;
        } else if (SalePhase == Phase.general) {
            return INDVIDUAL_GRAL_CONTRIB;
        } else {
            return TARGET_GOAL;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ICO Project
/// @author Agustin Bravo
/// @dev transfer and transferFrom functions overridden to substract 2% tax when enabled.
/// @notice Contract of Token SpaceCoin ERC20 compliant.
contract SpaceCoin is ERC20, Ownable {
    /// Constants used in constructor and for Tax Fee.
    uint256 constant ICO_SUPPLY = 150_000 * 10**18;
    uint256 constant TREASURY_SUPPLY = 350_000 * 10**18;
    uint256 constant TAX_FEE = 2;

    /// Immutable addresses initialized in the constructor from ICO contract.
    address public immutable treasuryAddress;
    address public immutable icoContractAddress;

    /**
     * @dev Owner can activate/deactivate transfer tax:
     * True: 2% Tax substracted from all transfer transactions to the treasury account.
     * False: Default when deployed, no tax.
     */
    bool public taxActive;

    /// Event emmited when owner ACTIVATES the 2% tax of transfer and transferFrom of the token.
    event TaxActive();

    /// Event emmited when owner DEACTIVATES the 2% tax of transfer and transferFrom of the token.
    event TaxInactive();

    constructor(
        address _treasuryAddress,
        address _icoContractAddress
    ) ERC20("Space Coin", "SPC") {
        treasuryAddress = _treasuryAddress;
        icoContractAddress = _icoContractAddress;
        _mint(_treasuryAddress, TREASURY_SUPPLY);
        _mint(_icoContractAddress, ICO_SUPPLY);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address from = _msgSender();
        uint256 fee = 0;
        if (taxActive && from != icoContractAddress && to != treasuryAddress) {
            fee = (amount * TAX_FEE) / 100;
        }
        // calculate sendAmount with fee
        uint256 sendAmount = amount - fee;
        if (fee > 0) {
            _transfer(from, treasuryAddress, fee);
            emit Transfer(from, treasuryAddress, fee);
        }
        _transfer(from, to, sendAmount);
        emit Transfer(from, to, sendAmount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        // initialize fee wiht 0, if tax is active fee gets calculated
        uint256 fee = 0;
        if (taxActive && from != icoContractAddress && to != treasuryAddress) {
            fee = (amount * TAX_FEE) / 100;
        }
        // check allowance and decrease the amount
        _spendAllowance(from, to, amount);
        // calculate sendAmount with fee
        uint256 sendAmount = amount - fee;
        if (fee > 0) {
            _transfer(from, treasuryAddress, fee);
            emit Transfer(from, treasuryAddress, fee);
        }
        _transfer(from, to, sendAmount);
        emit Transfer(from, to, sendAmount);
        return true;
    }

    function activateTax() external onlyOwner {
        require(!taxActive, "ALREADY_ACTIVE");
        taxActive = true;
        emit TaxActive();
    }

    function deactivateTax() external onlyOwner {
        require(taxActive, "ALREADY_INACTIVE");
        taxActive = false;
        emit TaxInactive();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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