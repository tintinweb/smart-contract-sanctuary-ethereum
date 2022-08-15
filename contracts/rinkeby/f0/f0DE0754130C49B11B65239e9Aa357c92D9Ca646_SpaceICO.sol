// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";
import "./Errors.sol";

contract SpaceICO {
    ///@dev The exchange rate of SPCE for 1 ether
    uint256 private constant EXCHANGE_RATE = 5;

    ///@dev Owner of this contract
    address public immutable owner;

    ///@dev Treasury of this contract
    address public immutable treasury;

    ///@dev Address of the SpaceCoin ERC-20 token
    SpaceCoin public spaceCoin;

    ///@dev ICO phase
    uint8 public phase;

    ///@dev An array of limit amounts. Each index designates the phase.
    Limit[] limitAmount;

    ///@dev Flag that denotes if a contract is paused
    bool public isPaused;

    ///@dev Whitelist of allowed participants
    mapping(address => bool) public whitelist;

    ///@dev Tracks the user token claimable contributed
    mapping(address => uint256) public claimableByUser;

    ///@dev Tracks the total amount of token claimable contributed
    uint256 public totalClaimable;


    event Claimed(address indexed purchaser, uint256 amount);
    event Purchased(address indexed purchaser, uint256 amount);
    event WhiteListChanged(address indexed member, bool change);
    event PhaseAdvanced(uint8 phase);

    enum Phase {
        SEED,
        GENERAL,
        OPEN
    }

    ///@dev The token limit purchasable for the phase and individual
    struct Limit {
        uint256 total; // Max 150,000 coins
        uint256 individual; 
    }

    modifier isPhase(Phase _phase) {
        if (uint8(_phase) != phase) revert WrongPhase(phase, uint8(_phase));
        _;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyTreasury {
        if (msg.sender != treasury) revert NotTreasury();
        _;
    }

    // Only applies during SEED phase
    modifier isWhitelisted {
        if (phase == uint8(Phase.SEED))
            if (!whitelist[msg.sender]) revert NotWhitelisted();
        _;
    }

    constructor(address _owner, address _treasury) {
        // TODO add address(0) checks
        owner = _owner;
        treasury = _treasury;

        // Deploy SPCE and mint to treasury
        spaceCoin = new SpaceCoin(_owner, _treasury, address(this), 500_000 * 10**18); // 18 is the decimal of SpaceCoin
        spaceCoin.mint(_treasury, 350_000 * 10**18);

        // SEED
        limitAmount.push(Limit(15_000 ether * EXCHANGE_RATE, 1_500 ether * EXCHANGE_RATE ));
        // GENERAL
        limitAmount.push(Limit(30_000 ether * EXCHANGE_RATE, 1_000 ether * EXCHANGE_RATE ));
        // OPEN
        limitAmount.push(Limit(30_000 ether * EXCHANGE_RATE, 30_000 ether * EXCHANGE_RATE )); // 150k is the absolute limit for the ICO
    }

    /**
     * @notice Advances the phases towards Phase.OPEN
     */
    function advancePhase() external onlyOwner {
        if (phase >= uint8(Phase.OPEN)) revert MaxPhaseReached();
        phase++;
        emit PhaseAdvanced(phase);
    }

    /**
     * @notice Mints the claimable contributions (only allowed during OPEN phase)
     */
    function claimTokens() external isPhase(Phase.OPEN) {
        uint256 amountToClaim = claimableByUser[msg.sender];
        if (amountToClaim == 0) revert NothingToClaim();
        
        claimableByUser[msg.sender] = 0;
        totalClaimable -= amountToClaim;
        spaceCoin.mint(msg.sender, amountToClaim);
        
        emit Claimed(msg.sender, amountToClaim);
    }

    /**
     * @notice Toggles between paused states
     */
    function pause() external onlyOwner {
        isPaused = !isPaused;
    }

    /**
     * @notice Payable function to allow purchases. 
     * All purchases are tracked using claimableByUser and totalClaimable
     */
    function purchase() external payable isWhitelisted {
        if (isPaused) revert OfferingPaused();

        uint256 spaceCoinToMint = msg.value * EXCHANGE_RATE;

        // Check if the individual phase limit will be hit with the latest contribution
        if (spaceCoinToMint > getIndividualLimitRemaining(msg.sender)) revert IndividualLimitHit();

        // Check if the total phase limit will be hit with the latest contribution
        if (totalClaimable + spaceCoinToMint > getPhaseLimitTotal()) revert PhaseLimitHit();
        
        claimableByUser[msg.sender] += spaceCoinToMint;
        totalClaimable += spaceCoinToMint;
        emit Purchased(msg.sender, spaceCoinToMint);
    }

    /**
     * @notice Toggles the member of the white list to be true/false
     */
    function setWhitelist(address member) external onlyOwner {
        whitelist[member] = !whitelist[member];
        emit WhiteListChanged(member, whitelist[member]);
    }

    /**
     * @notice Allows the treasury to withdraw an amount of eth
     * @param amount how much eth to withdraw
     */
    function withdrawInvestorFunds(uint256 amount) external onlyTreasury {
        if (amount > address(this).balance) revert InvalidAmount(amount);

        (bool success, ) = msg.sender.call{ value: amount }("");
        if (!success) revert TransferFailed();
    }

    /**
     * @notice Helper function returns the phase total limit 
     */
    function getPhaseLimitTotal() public view returns (uint256) {
        return limitAmount[phase].total;
    }

    /**
     * @notice Helper function that returns the phase individual limit
     */
    function getIndividualPhaseLimit() public view returns (uint256) {
        return limitAmount[phase].individual;
    }

    /**
     * @notice Helper function that returns remaining limit in ether 
     * @param individual address of look up
     */
    function getIndividualLimitRemaining(address individual) public view returns (uint256) {
        return getIndividualPhaseLimit() - claimableByUser[individual];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Errors.sol";

contract SpaceCoin is ERC20 {
    /// @notice The owner of this contract. Allows certain rights during ICO process
    address private immutable owner;

    /// @notice The address of the SPCE minter. Only this address can run mint(). 
    /// @dev Expected to be SpaceCoinICO contract
    address private immutable minter;

    /// @notice The treasury address. Used to deposit tax (if enabled)
    address public immutable treasury;

    /// @notice Max supply of SpaceCoin mintable
    uint256 public immutable maxSupply;

    /// @notice Percentage amount to tax
    uint8 public transferTaxPercentage = 0;

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyMinter {
        if (msg.sender != minter) revert NotMinter();
        _;
    }

    event Contributed();
    event Minted();
    event TransferTaxChanged(uint8 percentage);
    event TransferTaxApplied(uint256 amount);

    constructor(address _owner, address _treasury, address _minter, uint256 _maxSupply) ERC20("SpaceCoin", "SPCE") { // TODO Will hardcode the name for now but changable later
        // TODO add address(0) checks
        owner = _owner;
        treasury = _treasury;
        minter = _minter;
        maxSupply = _maxSupply;
    }

    /**
     * @notice mints a new amount of tokens to an address
     * @param to address to mint to
     * @param amount amount to mint    
     */
    function mint(address to, uint256 amount) external onlyMinter {
        if((totalSupply() + amount > maxSupply)) revert MaxTokensMinted();
        _mint(to, amount);
        emit Minted();
    }

    /**
     * @notice Toggles the transferTaxPercentage between 0 and 2
     */
    function toggleTransferTax() external onlyOwner {
        transferTaxPercentage = transferTaxPercentage == 0 ? 2 : 0; // TODO  2% is hardcoded but potentially allow this be to changeable
        emit TransferTaxChanged(transferTaxPercentage);
    }

    /**
     * @notice Overrides the ERC20._afterTokenTransfer hook to filter for transfers
     * @param from tranferring from address
     * @param to transfer to address
     * @param amount amount to transfer
     * @dev As best practice, leave as internal virtual. Also, see https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        /// @dev Done as best practice according to OZ. Does not do anything.
        super._afterTokenTransfer(from, to, amount);

        if (_isTokenTransfer(from, to, amount)) {
            if (transferTaxPercentage > 0) {
                _transferToTreasury(to, amount);
            }
        }
    }

    /**
     * @notice Helper function to determine if transfer. Excludes incoming treasury transfers 
     * @param from tranferring from address
     * @param to transfer to address
     * @param amount amount to transfer
     * @dev see openzeppelin docs
     */
    function _isTokenTransfer(address from, address to, uint256 amount) private view returns (bool) {
        return 
            from != address(0) && 
            to != address(0) && 
            to != treasury && // Excludes incoming treasury transfers 
            from != treasury && // Excludes outgoing treasury transfers 
            amount > 0;
    }

    /**
     * @notice Helper function to transfer an amount from an address to treasury
     * @param from transfer from address
     * @param amount amout to transfer
     * @dev see openzeppelin docs
     */
    function _transferToTreasury(address from, uint256 amount) private {
        uint256 amountForTreasury = amount * transferTaxPercentage / 100;
        _transfer(from, treasury, amountForTreasury);
        emit TransferTaxApplied(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error AddressAlreadySet();
error AddressZero();
error IndividualLimitHit();
error InvalidAmounts(uint256 ethAmount, uint256 spceAmount);
error InvalidAmount(uint256 amount);
error InsufficientTokenAmounts(uint256 expectedAmount, uint256 actualAmount);
error KHasBeenViolated(uint256 ethAmount, uint256 spceAmount);
error MaxTokensMinted();
error MaxPhaseReached();
error NothingToClaim();
error NotMinter();
error NotOwner();
error NotTreasury();
error NotEnoughTokens();
error NotWhitelisted();
error NotReadyToBeClaimed();
error OfferingPaused();
error PhaseLimitHit();
error TransferFailed();
error WrongPhase(uint8 current, uint8 lookingFor);

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