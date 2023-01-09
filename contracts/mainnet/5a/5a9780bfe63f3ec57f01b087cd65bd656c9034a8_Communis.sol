/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin\contracts\token\ERC20\extensions\ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: contracts\COM.sol

// Codeak
pragma solidity ^0.8.4;
interface _HEX { 
   function currentDay() external view returns (uint256);
   function stakeLists(address owner, uint256 stakeIndex) external view returns (uint40, uint72, uint72, uint16, uint16, uint16, bool);
   function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam) external;
   function globals() external view returns (
             uint72 lockedHeartsTotal
            ,uint72 nextStakeSharesTotal
            ,uint40 shareRate
            ,uint72 stakePenaltyTotal
            ,uint16 dailyDataCount
            ,uint72 stakeSharesTotal
            ,uint40 latestStakeId
            ,uint128 claimStats
            );
}

contract Communis is ERC20, ERC20Burnable {

    _HEX private HEX;

    address internal constant contract_creator = 0x3dEF1720Ce2B04a56f0ee6BC9875C64A785136b9;

    constructor() ERC20("Communis", "COM") {
        HEX = _HEX(address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39));
    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    enum BonusType {START, END, GOOD, RESTAKE}

    event newMint(
         uint256 data0
        ,uint256 data1
        ,uint256 indexed stakeId
        ,uint256 indexed bonusType
        ,address indexed senderAddr
        ,address referrer
    );

    event newDebtMint(
         uint256 data0
        ,address indexed senderAddr
    );

    event stakeDepositCodeak(
         uint256 data0
        ,address indexed senderAddr
    );

    event stakeWithdrawCodeak(
         uint256 data0
        ,address indexed senderAddr
    );

    struct PayoutResponse {
        uint256 recalculatedStakeShares;
        uint256 stakesOriginalShareRate;
        uint256 maxPayout;
    }

    struct Stake {
        uint256 stakeID;
        uint256 stakedHearts;
        uint256 stakeShares;
        uint256 lockedDay;
        uint256 stakedDays;
        uint256 unlockedDay;
    }

    struct RestakeEndDebt {
        uint16  stakedDays;
        uint16  endBonusPayoutDay;
        uint72  sharesDebt;
    }

    struct EndBonusDebt {
        uint16 nextPayoutDay;
        uint128 payoutDebt;
    }

    struct stakeIndexIdAmount {
        uint256 stakeIndex;
        uint256 stakeID;
        uint256 stakeAmount;
    }

    mapping(uint256 => uint256)                 public stakeIdStartBonusPayout;
    mapping(uint256 => uint256)                 public stakeIdEndBonusPayout;
    mapping(address => RestakeEndDebt)          public addressRestakeEndDebt;
    mapping(address => EndBonusDebt)            public addressEndBonusDebt;
    mapping(uint256 => uint256)                 public stakeIdGoodAccountingBonusPayout;
    mapping(address => uint256)                 public addressStakedCodeak;

    function memoryStake(address adr, uint256 stakeIndex, uint256 stakeID)
        internal view
        returns (Stake memory)
    {
        uint40 _stakeID;
        uint72 _stakedHearts;
        uint72 _stakeShares;
        uint16 _lockedDay;
        uint16 _stakedDays;
        uint16 _unlockedDay;

        (_stakeID, _stakedHearts, _stakeShares, _lockedDay, _stakedDays, _unlockedDay, ) = HEX.stakeLists(address(adr), stakeIndex);

        require(_stakeID == stakeID, "COM: Assure correct and current stake");

        return Stake(_stakeID, _stakedHearts, _stakeShares, _lockedDay, _stakedDays, _unlockedDay);
    }

    function getGlobalShareRate()
        internal view
        returns (uint256 shareRate)
    { 
        (, , shareRate, , , , , ) = HEX.globals(); 
    }

    function _emitNewMint(uint256 payout, uint256 stakedDays, uint256 recalculatedStakeShares, uint256 stakesOriginalShareRate, uint256 stakedHearts, uint256 stakeID, address referrer, BonusType bonusType)
        private
    {
        emit newMint(
            (uint256(uint128(payout)))
                | (uint256(uint128(recalculatedStakeShares)) << 128)
            ,uint256(uint40(block.timestamp))
                | (uint256(uint16(stakedDays))               << 40)
                | (uint256(uint40(stakesOriginalShareRate))  << 56)
                | (uint256(uint72(stakedHearts))             << 96)
            ,stakeID
            ,uint(bonusType)
            ,msg.sender
            ,referrer
        );
    }

    function _emitNewDebtMint(uint16 nextPayoutDay, uint256 payout, uint128 payoutDebt)
        private
    {
        emit newDebtMint(
             uint256(nextPayoutDay)
                | (uint256(uint112(payout)) << 16)
                | (uint256(payoutDebt)      << 128)
            ,msg.sender
        );
    }

    function _emitStakeDepositCodeak(uint256 amount, uint256 stakedCodeak)
        private
    {
        emit stakeDepositCodeak(
             uint256(uint128(amount))
                | (uint256(uint128(stakedCodeak)) << 128)
            ,msg.sender
        );
    }

    function _emitStakeWithdrawCodeak(uint256 amount, uint256 stakedCodeak)
        private
    {
        emit stakeWithdrawCodeak(
             uint256(uint128(amount))
                | (uint256(uint128(stakedCodeak)) << 128)
            ,msg.sender
        );
    }

    /**
     * 
     * @dev Reads current RestakeEndDebt
     * 
     * Maintains latest end bonus payout day
     * 
     * Maintains largest amount staked days
     * 
     * Accumulates stake's shares as total sharesDebt
     * 
     */
    function _updateRestakeEndDebt(uint256 currentDay, Stake memory s)
        private
    {
        RestakeEndDebt storage red = addressRestakeEndDebt[msg.sender];

        if(red.endBonusPayoutDay < currentDay) red.endBonusPayoutDay = uint16(currentDay);
        if(red.stakedDays < s.stakedDays) red.stakedDays = uint16(s.stakedDays);

        red.sharesDebt += uint72(s.stakeShares);
    }

    /**
     * 
     * @dev Reads current RestakeEndDebt
     * 
     * Assure new start stake (Stake Memory ss) meets requirements against RestakeEndDebt for Restake Bonus
     * 
     * Delete any restake debt if obligations are met
     * 
     */
    function _validateRestakeBonus(Stake memory ss)
        private
    {
        require(ss.stakedDays > 364, "COM: Minimum 365 staked days required");

        RestakeEndDebt storage red = addressRestakeEndDebt[msg.sender];

        require(red.endBonusPayoutDay != 0, "COM: No valid restake opportunity");
        require(ss.lockedDay > red.endBonusPayoutDay, "COM: Start Stake must be newer than previous stake");
        require(ss.stakedDays == 5555 || ss.stakedDays > red.stakedDays, "COM: New staked days must be greater than to previous");
        require(ss.stakeShares >= red.sharesDebt, "COM: Restake must at least maintain shares");     
        require(ss.stakeShares <= (red.sharesDebt * 2), "COM: Restake shares cannot be more than double");

        delete addressRestakeEndDebt[msg.sender];
    }

    /**
     * 
     * @dev Reverse engineer amount of bonus HEX hearts that were used in 
     * determining stake's HEX shares (this data is not kept in HEX storage)
     * 
     * Formula is derived from HEX smart contract
     * 
     */
    function getStakesBonusHearts(Stake memory s)
        internal pure
        returns (uint256 stakesBonusHearts)
    {
        uint256 cappedDays = 0;

        if (s.stakedDays > 1) cappedDays = s.stakedDays <= 3640 ? s.stakedDays - 1 : 3640;

        uint256 cappedHearts = s.stakedHearts <= (15 * (10 ** 15)) ? s.stakedHearts : (15 * (10 ** 15));

        stakesBonusHearts = s.stakedHearts * ((cappedDays * (15 * (10 ** 16))) + (cappedHearts * 1820)) / (273 * (10 ** 18)); 
    }

    /**
     * 
     * @dev Recalculate amount of bonus HEX hearts that would be applied if 
     * the cappedDays were not limited to 3640 days
     * 
     * Formula is derived from HEX smart contract
     * 
     */
    function getRecalculatedBonusHearts(Stake memory s)
        internal pure
        returns (uint256 recalculatedBonusHearts)
    {
        uint256 cappedDays = s.stakedDays - 1;

        uint256 cappedHearts = s.stakedHearts <= (15 * (10 ** 15)) ? s.stakedHearts : (15 * (10 ** 15));
 
        recalculatedBonusHearts = s.stakedHearts * ((cappedDays * (15 * (10 ** 16))) + (cappedHearts * 1820)) / (273 * (10 ** 18)); 
    }

    /**
     * 
     * @dev Creates a consistent PayoutResponse for any given Stake
     * 
     * Reverse engineer stakes original share rate as stakesOriginalShareRate using reverse engineered stakes bonus hearts
     * 
     * Recalculate Stake Shares with new Recalculated Bonus Hearts and using Reverse engineered stakesOriginalShareRate
     * 
     * Calculate penalty for amount days staked out of possible max length staked days of 5555, derived from HEX smart contract
     * 
     * Max payout represents the maximum possible value that can be minted for any given Stake
     * 
     */
    function getPayout(Stake memory s)
        public pure
        returns (PayoutResponse memory pr)
    {
        uint256 stakesOriginalShareRate = ((s.stakedHearts + getStakesBonusHearts(s)) * (10 ** 5)) / s.stakeShares;

        uint256 recalculatedStakeShares = (s.stakedHearts + getRecalculatedBonusHearts(s)) * (10 ** 17) / stakesOriginalShareRate;

        pr.stakesOriginalShareRate = stakesOriginalShareRate;
        pr.recalculatedStakeShares = recalculatedStakeShares;

        uint256 penalty = (s.stakedDays * (10 ** 15)) / 5555;
        pr.maxPayout = (recalculatedStakeShares * penalty) / (10 ** 15);
    }

    /**
     * 
     * @dev Creates a consistent payout for the Start Bonus given any Stake
     * 
     * If applyRestakeBonus, staked days range between 365 and 5555: 
     *      365 days gives bonusPercentage of 50000000000 and thus a 20% payout of maxPayout
     *      5555 days gives bonusPercentage of 20000000000 and thus a 50% payout of maxPayout
     * 
     * Else if staked days greater than 364, staked days range between 365 and 5555: 
     *      365 days gives bonusPercentage of 100000000000 and thus a 10% payout of maxPayout
     *      5555 days gives bonusPercentage of 40000000000 and thus a 25% payout of maxPayout
     * 
     * Else, staked days range between 180 and 364:
     *      180 days gives bonusPercentage of 200000000000 and thus a 5% payout of maxPayout
     *      364 days gives bonusPercentage of ~100540540540 and thus a ~9.946% payout of maxPayout
     * 
     * Penalty 
     *      global share rate is derived from HEX smart contract
     *      global share rate can only increase over time
     *      distance between current global share rate and reverse engineered stakes original share rate determine penalty
     * I.E.
     *      100,000 stakes share rate / 200,000 global share rate = you keep 50% of Start Bonus payout
     *      100,000 stakes share rate / 400,000 global share rate = you keep 25% of Start Bonus payout
     * 
     */
    function getStartBonusPayout(uint256 stakedDays, uint256 lockedDay, uint256 maxPayout, uint256 stakesOriginalShareRate, uint256 currentDay, uint256 globalShareRate, bool applyRestakeBonus)
        public pure
        returns (uint256 payout)
    {
        uint256 bonusPercentage;

        if(applyRestakeBonus == true) {
            bonusPercentage = (((stakedDays - 365) * (10 ** 10)) / 5190);
            bonusPercentage = ((3 * (10 ** 10)) * bonusPercentage) / (10 ** 10);
            bonusPercentage = (5 * (10 ** 10)) - bonusPercentage;
        }
        else if (stakedDays > 364) {
            bonusPercentage = ((stakedDays - 365) * (10 ** 10)) / 5190;
            bonusPercentage = ((6 * (10 ** 10)) * bonusPercentage) / (10 ** 10);
            bonusPercentage = (10 * (10 ** 10)) - bonusPercentage;
        }
        else {
            bonusPercentage = ((stakedDays - 180) * (10 ** 10)) / 185;
            bonusPercentage = ((10 * (10 ** 10)) * bonusPercentage) / (10 ** 10);
            bonusPercentage = (20 * (10 ** 10)) - bonusPercentage;
        }
 
        payout = (maxPayout * (10 ** 10)) / bonusPercentage;

        if(currentDay != lockedDay) {
            uint256 penalty = (stakesOriginalShareRate * (10 ** 15)) / globalShareRate;
            payout = (payout * penalty) / (10 ** 15);
        }
    }

    /**
     * 
     * @dev Allows withdraw of staked Codeak associated with msg.sender address
     * 
     */
    function withdrawStakedCodeak(uint256 withdrawAmount)
        external
    {
        require(withdrawAmount <= addressStakedCodeak[msg.sender], "COM: Requested withdraw amount is more than Address Staked Amount");

        addressStakedCodeak[msg.sender] -= withdrawAmount;

        _mint(msg.sender, withdrawAmount);
        _emitStakeWithdrawCodeak(withdrawAmount, addressStakedCodeak[msg.sender]);
    }

    /**
     * 
     * @dev External call to mint stake bonus for staking Codeak
     * 
     * Must have end bonus payout debt
     * 
     * Must have staked Codeak greater than or equal to end bonus payout debt
     * 
     */
    function mintStakeBonus()
        external
    {
        EndBonusDebt storage ebd = addressEndBonusDebt[msg.sender];
        if(ebd.payoutDebt != 0) {
            uint256 stakedCodeak = addressStakedCodeak[msg.sender];
            require(stakedCodeak >= ebd.payoutDebt, "COM: Address Staked Amount does not cover End Bonus Debt");
            _mintStakeBonus(ebd, HEX.currentDay(), stakedCodeak);
        }
    }

    /**
     * 
     * @dev Mints stake bonus for staking Codeak
     * 
     * Must have current day derived from HEX smart contract greater than next payout day
     * 
     * Calculates number of payouts based on distance between current day and next payout day
     * with no limit between the amount of days between them but in 91 day chunks
     *  
     * Sets next payout day depending on number of payouts minted
     * 
     */
    function _mintStakeBonus(EndBonusDebt storage ebd, uint256 currentDay, uint256 stakedCodeak)
        private
    {
        if(currentDay >= ebd.nextPayoutDay) {
            uint256 numberOfPayouts = ((currentDay - ebd.nextPayoutDay) / 91) + 1;
            uint256 payout = (stakedCodeak * numberOfPayouts) / 80;

            _mint(msg.sender, payout);

            ebd.nextPayoutDay += uint16(numberOfPayouts * 91);
            _emitNewDebtMint(ebd.nextPayoutDay, payout, ebd.payoutDebt);
        }
    }

    /**
     * 
     * @dev Allows batch minting of Start Bonuses to reduce gas costs
     * 
     */
    function mintStartBonusBatch(stakeIndexIdAmount[] calldata stakeIndexIdAmounts, address referrer)
        external
    {
        uint256 stakeIndexIdAmountsLength = stakeIndexIdAmounts.length;
        uint256 currentDay = HEX.currentDay();
        uint256 globalShareRate = getGlobalShareRate();

        for(uint256 i = 0; i < stakeIndexIdAmountsLength;){
            _mintStartBonus(stakeIndexIdAmounts[i].stakeIndex, stakeIndexIdAmounts[i].stakeID, false, referrer, currentDay, globalShareRate, stakeIndexIdAmounts[i].stakeAmount);
            unchecked {
                i++;
            }
        }
    }

    /**
     * 
     * @dev External call for single Start Bonuses
     * 
     */
    function mintStartBonus(uint256 stakeIndex, uint256 stakeID, bool applyRestakeBonus, address referrer, uint256 stakeAmount)
        external
    {
        _mintStartBonus(stakeIndex, stakeID, applyRestakeBonus, referrer, HEX.currentDay(), getGlobalShareRate(), stakeAmount);
    }

    /**
     * 
     * @dev Mints a bonus for starting a stake in HEX smart contract
     * 
     * Start bonus is only an upfront cut of the total max payout available for any given stake
     * 
     * Stake must not have its Start or End Bonus minted already
     * 
     * Stake shares must be at least 10000 to truncate low value edge cases
     * 
     * Start bonus forces minting Stake Bonus, if available, before staking new Codeak
     * 
     */
    function _mintStartBonus(uint256 stakeIndex, uint256 stakeID, bool applyRestakeBonus, address referrer, uint256 currentDay, uint256 globalShareRate, uint256 stakeAmount)
        private
    {
        require(stakeIdStartBonusPayout[stakeID] == 0, "COM: StakeID Start Bonus already minted");
        require(stakeIdEndBonusPayout[stakeID] == 0, "COM: StakeID End Bonus already minted");

        Stake memory s = memoryStake(address(msg.sender), stakeIndex, stakeID);

        require(s.stakeShares > 9999, "COM: Minimum 10000 shares required");
        require(s.stakedDays > 179, "COM: Minimum 180 staked days required");
        
        require(currentDay >= s.lockedDay, "COM: Stake not Active");

        BonusType bt = BonusType.START;
        if(applyRestakeBonus == true) {
            _validateRestakeBonus(s);
            bt = BonusType.RESTAKE;
        }

        PayoutResponse memory pr = getPayout(s);

        uint256 payout = getStartBonusPayout(s.stakedDays, s.lockedDay, pr.maxPayout, pr.stakesOriginalShareRate, currentDay, globalShareRate, applyRestakeBonus);

        if(referrer == msg.sender) {
            payout += (payout / 100);
        }
        else if(referrer != address(0)) {
            _mint(referrer, (payout / 100));
        }
        else {
            _mint(contract_creator, (payout / 100));
        }

        stakeIdStartBonusPayout[stakeID] = payout;

        EndBonusDebt storage ebd = addressEndBonusDebt[msg.sender];

        if(ebd.payoutDebt != 0 && addressStakedCodeak[msg.sender] >= ebd.payoutDebt) _mintStakeBonus(ebd, currentDay, addressStakedCodeak[msg.sender]);

        if(stakeAmount > 0) {
            require(stakeAmount <= payout, "COM: Stake amount is more than available payout");

            addressStakedCodeak[msg.sender] += stakeAmount;

            payout -= stakeAmount;

            _emitStakeDepositCodeak(stakeAmount, addressStakedCodeak[msg.sender]);
        }

        if(payout > 0) _mint(msg.sender, payout);
        _emitNewMint(payout, s.stakedDays, pr.recalculatedStakeShares, pr.stakesOriginalShareRate, s.stakedHearts, s.stakeID, referrer, bt);
    }

    /**
     * 
     * @dev Allows batch minting of End Bonuses to reduce gas costs
     * 
     */
    function mintEndBonusBatch(stakeIndexIdAmount[] calldata stakeIndexIdAmounts, address referrer)
        external
    {
        uint256 stakeIndexIdAmountsLength = stakeIndexIdAmounts.length;
        uint256 currentDay = HEX.currentDay();

        for(uint256 i = 0; i < stakeIndexIdAmountsLength;){
            _mintEndBonus(stakeIndexIdAmounts[i].stakeIndex, stakeIndexIdAmounts[i].stakeID, referrer, currentDay, stakeIndexIdAmounts[i].stakeAmount);
            unchecked {
                i++;
            }
        }
    }

    /**
     * 
     * @dev External call for single End Bonuses
     * 
     */
    function mintEndBonus(uint256 stakeIndex, uint256 stakeID, address referrer, uint256 stakeAmount)
        external
    {
        _mintEndBonus(stakeIndex, stakeID, referrer, HEX.currentDay(), stakeAmount);
    }

    /**
     * 
     * @dev Mints a bonus for fulfilling a stakes staked days commitment in HEX smart contract
     * 
     * End bonus is the remaining total max payout available for any given stake, reduced only based on previous Start Stake Bonus minted
     * 
     * Stake must not have its End Bonus minted already
     * 
     * Stake shares must be at least 10000 to truncate low value edge cases
     * 
     * 50% of End Bonus Payout is accumulated as End Bonus Debt
     * 
     * End bonus forces minting Stake Bonus, if available, before staking new Codeak
     * 
     * Allows staking new Codeak before checking if staked Codeak is less than End Bonus Debt
     * 
     */
    function _mintEndBonus(uint256 stakeIndex, uint256 stakeID, address referrer, uint256 currentDay, uint256 stakeAmount)
        private
    {
        require(stakeIdEndBonusPayout[stakeID] == 0, "COM: StakeID End Bonus already minted");

        Stake memory s = memoryStake(address(msg.sender), stakeIndex, stakeID);

        require(s.stakedDays > 364, "COM: Minimum 365 staked days required");
        require(s.stakeShares > 9999, "COM: Minimum 10000 shares required");

        uint256 dueDay = s.lockedDay + s.stakedDays;
        require(currentDay >= dueDay, "COM: Stake not due");
        require(currentDay <= dueDay + 37, "COM: Grace period ended");

        PayoutResponse memory pr = getPayout(s);

        uint256 payout = pr.maxPayout - stakeIdStartBonusPayout[stakeID];

        if(referrer == msg.sender) {
            payout += (payout / 100);
        }
        else if(referrer != address(0)) {
            _mint(referrer, (payout / 100));
        }
        else {
            _mint(contract_creator, (payout / 100));
        }

        stakeIdEndBonusPayout[stakeID] = payout;

        uint128 payoutDebt = uint128(payout / 2);

        EndBonusDebt storage ebd = addressEndBonusDebt[msg.sender];

        if(ebd.payoutDebt != 0) _mintStakeBonus(ebd, currentDay, addressStakedCodeak[msg.sender]);

        if(stakeAmount > 0) {
            require(stakeAmount <= payout, "COM: Stake amount is more than available payout");

            addressStakedCodeak[msg.sender] += stakeAmount;

            payout -= stakeAmount;
            
            _emitStakeDepositCodeak(stakeAmount, addressStakedCodeak[msg.sender]);
        }

        if(ebd.payoutDebt != 0) require(addressStakedCodeak[msg.sender] >= ebd.payoutDebt, "COM: Address Staked Amount does not cover End Bonus Debt");
        else ebd.nextPayoutDay = uint16(currentDay) + 91;

        if(payout > 0) _mint(msg.sender, payout);
        _emitNewMint(payout, s.stakedDays, pr.recalculatedStakeShares, pr.stakesOriginalShareRate, s.stakedHearts, s.stakeID, referrer, BonusType.END);

        _updateRestakeEndDebt(currentDay, s);
        ebd.payoutDebt += payoutDebt;
    }

    /**
     * 
     * @dev Mints a bonus for cleaning stale shares in the HEX smart contract
     * 
     * Stake must not already be unlocked 
     * 
     * Stake must not have its End or Good Accounting Bonus minted already
     * 
     */
    function mintGoodAccountingBonus(address stakeOwner, uint256 stakeIndex, uint256 stakeID)
        external
    {
        require(stakeIdGoodAccountingBonusPayout[stakeID] == 0, "COM: StakeID Good Accounting Bonus already minted");
        require(stakeIdEndBonusPayout[stakeID] == 0, "COM: StakeID End Bonus already minted");

        Stake memory s = memoryStake(address(stakeOwner), stakeIndex, stakeID);

        require(s.stakeShares > 9999, "COM: Minimum 10000 shares required");
        require(s.unlockedDay == 0, "COM: Stake already unlocked");
        require(HEX.currentDay() > s.lockedDay + s.stakedDays + 37, "COM: Grace period has not ended");

        HEX.stakeGoodAccounting(address(stakeOwner), stakeIndex, uint40(stakeID));

        Stake memory sga = memoryStake(address(stakeOwner), stakeIndex, stakeID);
        require(sga.unlockedDay != 0, "COM: Stake did not have Good Accounting ran");

        PayoutResponse memory pr = getPayout(s);

        uint256 payout = pr.maxPayout / 100;

        stakeIdGoodAccountingBonusPayout[stakeID] = payout;

        _mint(msg.sender, payout);
        _emitNewMint(payout, s.stakedDays, pr.recalculatedStakeShares, pr.stakesOriginalShareRate, s.stakedHearts, s.stakeID, address(0), BonusType.GOOD);
    }
}