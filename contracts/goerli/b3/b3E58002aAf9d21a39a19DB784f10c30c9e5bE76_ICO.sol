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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";

contract ICO {
    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    ///////////////////////////////////////////////////////////////*/

    /// @dev Seed Phase Contribution Limits
    uint256 private constant MAX_TOTAL_CONTRIBUTION_SEED = 15000 ether;
    uint256 private constant MAX_INDIVIDUAL_CONTRIBUTION_SEED = 1500 ether;

    /// @dev General Phase Contribution Limits
    uint256 private constant MAX_TOTAL_CONTRIBUTION_GENERAL = 30000 ether;
    uint256 private constant MAX_INDIVIDUAL_CONTRIBUTION_GENERAL = 1000 ether;

    /// @dev Open Phase Contribution Limit
    uint256 private constant MAX_TOTAL_CONTRIBUTION_OPEN = 30000 ether;

    /// @notice contract's owner address
    address public immutable owner;

    /// @notice address which receives tax on token transfers
    address public immutable treasury;

    /// @notice coin (token) being offered
    SpaceCoin public immutable spaceCoin;

    /*///////////////////////////////////////////////////////////////
                                State
    ///////////////////////////////////////////////////////////////*/

    /// @notice enum to represent the three phases of ICO
    /// (see: https://github.com/0xMacro/student.JaredBorders/tree/master/ico#technical-spec)
    enum Phase {
        Seed,
        General,
        Open
    }

    /// @notice represents current phase
    Phase public phase = Phase.Seed;

    /// @notice toggle that pauses both fundraising and token redemptions
    /// @dev 1 == false, 2 == true
    uint8 public paused = 1;

    /// @notice private investors who have been added to the ICO's allowlist
    mapping(address => bool) public allowlist;

    /// @notice track total ETH contributions
    /// @dev this ONLY represents ETH contributed via `contribute()`
    uint256 public totalContributed;

    /// @notice track how much ETH a specific address has contributed
    /// @dev this ONLY represents ETH contributed via `contribute()`
    mapping(address => uint256) public contributed;

    /*///////////////////////////////////////////////////////////////
                                Events
    ///////////////////////////////////////////////////////////////*/

    /// @notice emits when phase is advanced by owner
    /// @param _phase: phase being advanced *TO* (i.e. the new phase)
    event PhaseAdvancedTo(Phase _phase);

    /// @notice emits when ICO is paused
    /// @param _whenIcoWasPaused: timestamp of when paused
    event Paused(uint256 _whenIcoWasPaused);

    /// @notice emits when ICO is resumed
    /// @param _whenIcoWasResumed: timestamp of when resumed
    event Resumed(uint256 _whenIcoWasResumed);

    /// @notice emits when account contributes ETH to ICO
    /// @param _contributor: address of contributor
    /// @param _currentPhase: phase when contribution occured
    /// @param _amount: amount of ETH contributed
    event Contributed(
        address indexed _contributor,
        Phase _currentPhase,
        uint256 _amount
    );

    /// @notice emits when account redeems SPC from ICO in the Open Phase
    /// @param _redeemer: address of redeemer
    /// @param _amount: amount of SPC redeemed
    event Redeemed(address indexed _redeemer, uint256 _amount);

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    ///////////////////////////////////////////////////////////////*/

    /// @notice check if caller address is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "ICO: Only Owner");
        _;
    }

    /// @notice check if contract is *NOT* paused
    /// @dev 1 == false, 2 == true
    modifier isNotPaused() {
        require(paused == 1, "ICO: ICO is Paused");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor
    ///////////////////////////////////////////////////////////////*/

    /// @param _owner: contract's owner address
    /// @param _tokenOwner: SpaceCoin contract's owner address
    /// @param _treasury: address which receives tax on token transfers
    constructor(
        address _owner,
        address _tokenOwner,
        address _treasury
    ) {
        // set auth and treasury
        owner = _owner;
        treasury = _treasury;

        // deploy SpaceCoin (SPC)
        spaceCoin = new SpaceCoin(_tokenOwner, address(this), _treasury);
    }

    /*///////////////////////////////////////////////////////////////
                            Phase Management
    ///////////////////////////////////////////////////////////////*/

    /// @notice attempt to advance to next phase of ICO
    /// @dev cannot advance past Phase Open
    function advancePhase() external onlyOwner {
        if (phase == Phase.Seed) {
            phase = Phase.General;
        } else if (phase == Phase.General) {
            phase = Phase.Open;
        } else {
            revert("ICO: Cannot Advance");
        }

        emit PhaseAdvancedTo(phase);
    }

    /// @notice pause ICO contract
    function pause() external onlyOwner {
        paused = 2;

        emit Paused(block.timestamp);
    }

    /// @notice resume (i.e. un-pause) ICO contract
    function resume() external onlyOwner {
        paused = 1;

        emit Resumed(block.timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                            Allowlist Logic
    ///////////////////////////////////////////////////////////////*/

    /// @notice add address to allowlist
    /// @param _address: address to be added
    function addUserToAllowlist(address _address) external onlyOwner {
        allowlist[_address] = true;
    }

    /// @notice check if address is in allowlist
    /// @param _address: address to be checked
    /// @return true if address is in allowlist
    function isAddressInAllowlist(address _address) public view returns (bool) {
        return allowlist[_address];
    }

    /*///////////////////////////////////////////////////////////////
                        Contribution & Redemptions
    ///////////////////////////////////////////////////////////////*/

    /// @notice caller can contribute ETH to ICO
    /// @dev contribution success dependent on Phase
    /// @dev cannot contribute is ICO is paused
    function contribute() external payable isNotPaused {
        require(msg.value > 0, "ICO: Invalid Contribution");

        if (phase == Phase.Seed) {
            // check account is allowed to contribute in Seed Phase
            require(allowlist[msg.sender], "ICO: Not In Allowlist");

            // check contribution is valid
            require(
                contributed[msg.sender] + msg.value <= MAX_INDIVIDUAL_CONTRIBUTION_SEED,
                "ICO: Individual Limit Exceeded"
            );
            require(
                totalContributed + msg.value <= MAX_TOTAL_CONTRIBUTION_SEED,
                "ICO: Phase Limit Exceeded"
            );

            // update internal accounting
            contributed[msg.sender] += msg.value;
            totalContributed += msg.value;

            emit Contributed(msg.sender, Phase.Seed, msg.value);
        } else if (phase == Phase.General) {
            // check contribution is valid
            require(
                contributed[msg.sender] + msg.value <=
                    MAX_INDIVIDUAL_CONTRIBUTION_GENERAL,
                "ICO: Individual Limit Exceeded"
            );
            require(
                totalContributed + msg.value <= MAX_TOTAL_CONTRIBUTION_GENERAL,
                "ICO: Phase Limit Exceeded"
            );

            // update internal accounting
            contributed[msg.sender] += msg.value;
            totalContributed += msg.value;

            emit Contributed(msg.sender, Phase.General, msg.value);
        } else {
            // check contribution is valid
            require(
                totalContributed + msg.value <= MAX_TOTAL_CONTRIBUTION_OPEN,
                "ICO: Phase Limit Exceeded"
            );

            // update internal accounting
            contributed[msg.sender] += msg.value;
            totalContributed += msg.value;

            emit Contributed(msg.sender, Phase.Open, msg.value);
        }
    }

    /// @notice caller redeems SPC 
    /// @dev will redeem all current SPC available to them
    function redeem() external isNotPaused {
        // Can only redeem SPC in Open Phase
        require(phase == Phase.Open, "ICO: Unable To Redeem");

        // Determine amount of SPC which will be redeemed
        uint256 amount = contributed[msg.sender] * 5;
        require(amount > 0, "ICO: Nothing To Redeem");

        // update internal accounting
        contributed[msg.sender] = 0;

        // redeem SPC at exchange rate defined above
        spaceCoin.transfer(msg.sender, amount);

        emit Redeemed(msg.sender, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    ///////////////////////////////////////////////////////////////*/

    /// @notice the tokens minted to the ICO at construction
    uint256 private constant ICO_SUPPLY = 150000e18;

    /// @notice the tokens minted to the treasury at construction
    uint256 private constant TREASURY_SUPPLY = 350000e18;

    /// @notice tax amount imposed on every token transfer
    /// @dev denoted in basis points
    uint256 private constant TAX = 200; // 2%

    /// @notice max BPS
    uint256 private constant MAX_BPS = 10000;

    /// @notice contract's owner address
    /// @dev can impose or remove transfer tax via `flag`
    address public immutable owner;

    /// @notice address of ICO contract
    address public immutable ico;

    /// @notice address which receives tax on token transfers
    address public immutable treasury;

    /*///////////////////////////////////////////////////////////////
                                State
    ///////////////////////////////////////////////////////////////*/

    /// @notice flag that toggles tax on/off
    bool public flag;

    /*///////////////////////////////////////////////////////////////
                                Events
    ///////////////////////////////////////////////////////////////*/

    /// @notice emitted when setFlag() has been called successfully
    event FlagSet(bool _flag);

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    ///////////////////////////////////////////////////////////////*/

    /// @notice check if caller address is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "SpaceCoin: Only Owner");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor
    ///////////////////////////////////////////////////////////////*/

    /// @notice setup ERC20 token SpaceCoin
    /// @param _owner: contract's owner address
    /// @param _ico: address of ICO contract
    /// @param _treasury: address which receives tax on token transfers
    constructor(
        address _owner,
        address _ico,
        address _treasury
    ) ERC20("SpaceCoin", "SPC") {
        owner = _owner;
        treasury = _treasury;
        ico = _ico;

        // mint 150_000 SPC to this address (ICO)
        _mint(_ico, ICO_SUPPLY);

        // mint 350_000 SPC to treasury address
        _mint(_treasury, TREASURY_SUPPLY);
    }

    /*///////////////////////////////////////////////////////////////
                    Only Owner External Functions
    ///////////////////////////////////////////////////////////////*/

    /// @notice enable/disable tax
    /// @dev only contract owner can call this function
    /// @dev does not check if _flag already equals flag
    /// @param _flag: new value for flag
    function setFlag(bool _flag) external onlyOwner {
        flag = _flag;
        emit FlagSet(_flag);
    }

    /*///////////////////////////////////////////////////////////////
                        Tax Logic Overrides
    ///////////////////////////////////////////////////////////////*/

    /// @dev See {ERC20-transfer}
    /// @dev tax may be imposed on transfers
    /// Requirements:
    /// - `to` cannot be the zero address.
    /// - the caller must have a balance of at least `amount`.
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        // calculate tax if flag is set to true
        if (flag) {
            uint256 taxImposed = (amount * TAX) / MAX_BPS;
            amount -= taxImposed;
            _transfer(_msgSender(), treasury, taxImposed);
        }

        _transfer(_msgSender(), to, amount);
        return true;
    }

    /// @dev See {ERC20-transferFrom}
    /// @dev tax may be imposed on transfers
    /// Emits an {Approval} event indicating the updated allowance. This is not
    /// required by the EIP. See the note at the beginning of {ERC20}.
    /// NOTE: Does not update the allowance if the current allowance
    /// is the maximum `uint256`.
    /// Requirements:
    /// - `from` and `to` cannot be the zero address.
    /// - `from` must have a balance of at least `amount`.
    /// - the caller must have allowance for ``from``'s tokens of at least `amount`
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();

        // calculate tax if flag is set to true
        if (flag) {
            uint256 taxImposed = (amount * TAX) / MAX_BPS;
            amount -= taxImposed;
            _transfer(from, treasury, taxImposed);
        }

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}