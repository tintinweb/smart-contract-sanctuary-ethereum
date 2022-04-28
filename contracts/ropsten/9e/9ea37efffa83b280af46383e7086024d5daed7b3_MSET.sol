/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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

interface IVesting{
    function setupVesting(uint256 cliff_, uint256 vestingT_, uint256 vestingA_, uint256 totalVesting_, address account_) external;
    function checkLocked(address account_) external returns(uint256);
}

// ----------------------------------------------------------------------------
// 'MSET' token contract

// Symbol      : MSET
// Name        : MEGASET
// Total supply: 10,000,000,000
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// BEP20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract MSET is IBEP20, Ownable, IBEP20Metadata  {
    using SafeMath for uint256;
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
        _mint(address(this), 10000000000 * 10 ** (decimals()));
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
        _transfer(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender) public view virtual override returns (uint256) {
        return _allowances[owner_][spender];
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
        _approve(_msgSender(), spender, amount);
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
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
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
        uint256 currentAllowance = allowance(_msgSender(), spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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

        _beforeTokenTransfer(from, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance.sub(amount);
        _balances[to] = _balances[to].add(amount);

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

        _totalSupply = _totalSupply.add(amount);

        allocateTokens();
        setupInternalVesting();
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
        // checks the currently locked tokens
        uint256 locked = checkLocked(account);
        require(locked == 0, "Cannot burn unless all tokens are released");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
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
        address owner_a,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner_a != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_a][spender] = amount;
        emit Approval(owner_a, spender, amount);
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
        address owner_s,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_s, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner_s, spender, currentAllowance.sub(amount));
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
        /*address to,*/
        uint256 amount
    ) internal virtual {
        uint256 locked = checkLocked(from);
        if(locked > 0) {
            uint256 unlocked = _balances[from].sub(locked);
            require(amount <= unlocked, "tokens are locked");
        }
    }

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
    ) internal virtual {
    }


    address constant private presale1Add = 0x4fA0964B99452B3C23F0A2BEA248409cF3c62730;
    address constant private presale2Add = 0xeb24328579E1C618d9fe8C8070D12d5faD26dB58;
    address constant private presale3Add = 0xd694F76db0523899638d259F0cB1b34B26af64fb;
    address constant private publicSale = 0x67501083Cc6165d2AcCe90d97227103453Fd221c;
    address constant private liquidity = 0x1ec5674eCEf7B8122535c31CE81967e9F04b0fB3;
    uint256 private liquidityT = 200000000 * 10 ** (decimals());
    address constant private cexListing = 0x032013BCB45B4648FCe54F11177a2A246f67826C;
    address constant private team = 0x9E457bb588DB3A762140E98a51C04992a8EDCC08;
    uint256 private teamT = 100000000 * 10 ** (decimals());
    address constant private advisors = 0x6B0b76B270e08CA6c36c9523c784B593442fbBd2;
    uint256 private advisorsT = 100000000 * 10 ** (decimals());
    address constant private rewardsEcosystem = 0x438dD079aB86ac54B458a9aCe1be41513D19cf58;
    uint256 private rewardEcosystemT = 7600000000 * 10 ** (decimals());
    address constant private marketing = 0x200ef1688AFB4AB362a4c4BF9BDb5e273e2FBd31;
    uint256 private marketingT = 200000000 * 10 ** (decimals());

    // this function will allocate the tokens to the specified internal accounts
    function allocateTokens() internal {
        mintNew_(presale1Add, 100000000 * 10 ** (decimals()));
        mintNew_(presale2Add, 100000000 * 10 ** (decimals()));
        mintNew_(presale3Add, 100000000 * 10 ** (decimals()));
        mintNew_(publicSale, 500000000 * 10 ** (decimals()));
        mintNew_(liquidity, liquidityT);
        mintNew_(cexListing, 1000000000 * 10 ** (decimals()));
        mintNew_(team, teamT);
        mintNew_(advisors, advisorsT);
        mintNew_(rewardsEcosystem, rewardEcosystemT);
        mintNew_(marketing, marketingT);
    }

    // this function will mint the tokens internally
    function mintNew_(address account_, uint256 amount_) private{
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(0), account_, amount_);
    }

    // this set up vesting for internal accounts
    function setupInternalVesting() private {
        setupVesting(0                     , 7776000 /*3 months*/, liquidityT.div(4), liquidityT, liquidity);
        setupVesting(31536000 /*12 months*/, 2629800 /*1 months*/, teamT.div(48), teamT, team);
        setupVesting(31536000 /*12 months*/, 2629800 /*1 months*/, advisorsT.div(48), advisorsT, advisors);
        setupVesting(31536000 /*12 months*/, 2629800 /*1 months*/, marketingT.div(36), marketingT, marketing);
        setupVesting(18403200 /*7 months*/, 2629800 /*1 months*/, rewardEcosystemT.div(60), rewardEcosystemT, rewardsEcosystem);
    }
 

    uint256 public publicSaleDate; // the date of public sale, after which vesting release will start

    // users can use this function to burn tokens from their account
    function burn(uint256 amount) external returns(bool){
        _burn(_msgSender(), amount);
        return true;
    }

    event publicSaleDateUpdated(uint256 _oldDate, uint256 _newDate);
    // owner will use this function to set the public sale date
    function setPublicSaleDate(uint256 publicSaleD_) external onlyOwner{
        require(publicSaleD_ > block.timestamp, "Invalid date");
        emit publicSaleDateUpdated(publicSaleDate, publicSaleD_);
        publicSaleDate = publicSaleD_;
    }

    struct VestingSchedule{
        uint256 cliff;
        uint256 vestingTime;
        uint256 vestingAmt;
        uint256 vestingAmtLeft;
        uint256 lastReleaseMonth;
    }

    mapping(address => VestingSchedule) internal locking; // saves vesting of internal accounts
    mapping(address => VestingSchedule) internal presale1Locking; // saves vesting of presale 1 accounts
    mapping(address => VestingSchedule) internal presale2Locking; // saves vesting of presale 2 accounts
    mapping(address => VestingSchedule) internal presale3Locking; // saves vesting of presale 3 accounts

    address private presale1CAddress;
    address private presale2CAddress;
    address private presale3CAddress;

    modifier onlyPreSale1C{
        require(_msgSender() == presale1CAddress, "UnAuthorized");
        _;
    }

    modifier onlyPreSale2C{
        require(_msgSender() == presale2CAddress, "UnAuthorized");
        _;
    }

    modifier onlyPreSale3C{
        require(_msgSender() == presale3CAddress, "UnAuthorized");
        _;
    }

    // internal function to set vesting from internal accounts
    function setupVesting(uint256 cliff_, uint256 vestingT_, uint256 vestingA_, uint256 totalVesting_, address account_) private{
        locking[account_].cliff = cliff_;
        locking[account_].vestingTime = vestingT_;
        locking[account_].vestingAmt = vestingA_;
        locking[account_].vestingAmtLeft = totalVesting_;
    }

    // sets vesting of presale 1 accounts
    // only callable by presale 1 contract
    function setupP1Vesting(uint256 cliff_, uint256 vestingT_, uint256 vestingA_, uint256 totalVesting_, address account_) external onlyPreSale1C{
        presale1Locking[account_].cliff = cliff_;
        presale1Locking[account_].vestingTime = vestingT_;
        presale1Locking[account_].vestingAmt = presale1Locking[account_].vestingAmt.add(vestingA_);
        presale1Locking[account_].vestingAmtLeft = presale1Locking[account_].vestingAmtLeft.add(totalVesting_);
    }
    // sets vesting of presale 2 accounts
    // only callable by presale 2 contract
    function setupP2Vesting(uint256 cliff_, uint256 vestingT_, uint256 vestingA_, uint256 totalVesting_, address account_) external onlyPreSale2C{
        presale2Locking[account_].cliff = cliff_;
        presale2Locking[account_].vestingTime = vestingT_;
        presale2Locking[account_].vestingAmt = presale2Locking[account_].vestingAmt.add(vestingA_);
        presale2Locking[account_].vestingAmtLeft = presale2Locking[account_].vestingAmtLeft.add(totalVesting_);
    }

    // sets vesting of presale 3 accounts
    // only callable by presale 3 contract
    function setupP3Vesting(uint256 cliff_, uint256 vestingT_, uint256 vestingA_, uint256 totalVesting_, address account_) external onlyPreSale3C{
        presale3Locking[account_].cliff = cliff_;
        presale3Locking[account_].vestingTime = vestingT_;
        presale3Locking[account_].vestingAmt = presale3Locking[account_].vestingAmt.add(vestingA_);
        presale3Locking[account_].vestingAmtLeft = presale3Locking[account_].vestingAmtLeft.add(totalVesting_);
    }

    // this function will be called by UI / Users to get the locked tokens value
    function lockedTokens(address account_) public view returns(uint256){
        uint256 locked = 0;
        uint256 amtL__;
        uint256 tP__;

        // the account is from internal team
        if(locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL__, tP__) = updateVesting_(locking[account_], publicSaleDate);
            locked = locked.add(amtL__);
        }
        
        // the account is from presale 1 
        if(presale1Locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL__, tP__) = updateVesting_(presale1Locking[account_], publicSaleDate);
            locked = locked.add(amtL__);
        }

        // the account is from presale 2 
        if(presale2Locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL__, tP__) = updateVesting_(presale2Locking[account_], publicSaleDate);
            locked = locked.add(amtL__);
        }

        // the account is from presale 3 
        if(presale3Locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL__, tP__) = updateVesting_(presale3Locking[account_], publicSaleDate);
            locked = locked.add(amtL__);
        }

        return locked;
    }
    
    // checks the locked tokens in account
    function checkLocked(address account_) private view returns(uint256) {
        uint256 locked = 0;
        uint256 amtL;
        uint256 tP;
        // the account is from internal team
        if(locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL, tP) = updateVesting_(locking[account_], publicSaleDate);
            update(locking[account_], amtL, tP);
            locked = locked.add(amtL);

        }
        
        // the account is from presale 1 
        if(presale1Locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL, tP) = updateVesting_(presale1Locking[account_], publicSaleDate);
            update(presale1Locking[account_], amtL, tP);
            locked = locked.add(amtL);
        }

        // the account is from presale 2 
        if(presale2Locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL, tP) = updateVesting_(presale2Locking[account_], publicSaleDate);
            update(presale2Locking[account_], amtL, tP);
            locked = locked.add(amtL);
        }

        // the account is from presale 3 
        if(presale3Locking[account_].vestingAmtLeft > 0){ 
            // update vesting
            (amtL, tP) = updateVesting_(presale3Locking[account_], publicSaleDate);
            update(presale3Locking[account_], amtL, tP);
            locked = locked.add(amtL);
        }

        return locked;
    }

    // updates the locked tokens in account
    function updateVesting_(VestingSchedule memory vestingAcc, uint256 publicSaleDate_) private view returns(uint256 amountL, uint256 timeP){
        if(vestingAcc.vestingAmtLeft > 0 && publicSaleDate_ != 0){
            uint256 cliffD_ = publicSaleDate_.add(vestingAcc.cliff);
            require(block.timestamp > cliffD_, "cliff period has not ended");
            uint256 vestingTPassed = (block.timestamp.sub(cliffD_)).div(vestingAcc.vestingTime);
            vestingTPassed = vestingTPassed.add(1);
            vestingTPassed = vestingTPassed.sub(vestingAcc.lastReleaseMonth);

            // increment of vestingTPassed is done for the following reason:
            // cliff time has expired but first month after vesting has not reached
            // release the 0th period amount

            uint256 amountL_ = vestingAcc.vestingAmtLeft.sub(vestingAcc.vestingAmt.mul(vestingTPassed));
            uint256 timeP_ = vestingTPassed;
            if(amountL_ < vestingAcc.vestingAmt)
                amountL_ = 0;

            return (amountL_, timeP_);
        }
    }

    function update(VestingSchedule memory vestingAcc, uint256 amountL, uint256 timeP) private pure {
        vestingAcc.vestingAmtLeft = amountL;
        vestingAcc.lastReleaseMonth = timeP;
    }

    event Presale1AddressUpdated(address oldAddress, address newAddress);
    event Presale2AddressUpdated(address oldAddress, address newAddress);
    event Presale3AddressUpdated(address oldAddress, address newAddress);

    // owner can set presale 1 address
    function setPresale1Address(address address_) external onlyOwner{
        require(address_ != address(0), "Zero address not allowed");
        emit Presale1AddressUpdated(presale1CAddress, address_);
        presale1CAddress = address_;
    }

    // owner can set presale 2 address
    function setPresale2Address(address address_) external onlyOwner{
        require(address_ != address(0), "Zero address not allowed");
        emit Presale2AddressUpdated(presale2CAddress, address_);
        presale2CAddress = address_;
    }

    // owner can set presale 3 address
    function setPresale3Address(address address_) external onlyOwner{
        require(address_ != address(0), "Zero address not allowed");
        emit Presale3AddressUpdated(presale3CAddress, address_);
        presale3CAddress = address_;
    }

}