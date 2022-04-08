/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// File: default_workspace/Interfaces/IPErc20.sol



pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IErc20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @param a Adress to fetch balance of
     */
    function balanceOf(address a) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @param r The recipient
     * @param a The amount transferred
     *
     * Emits a {Transfer} event.
     */
    function transfer(address r, uint256 a) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * @param o The owner
     * @param s The spender
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address o, address s) external view returns (uint256);

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
     * @param s The spender
     * @param a The amount to approve
     *
     * Emits an {Approval} event.
     */
    function approve(address s, uint256 a) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @param s The sender
     * @param r The recipient
     * @param a The amount to transfer
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address s, address r, uint256 a) external returns (bool);

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
}
// File: default_workspace/ERC/ERC20.sol



pragma solidity 0.8.4;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * NOTES: This is an adaptation of the Open Zeppelin ERC20, with changes made per audit
 * requests, and to fit overall Swivel Style. We use it specifically as the base for
 * the Erc2612 hence the `Perc` (Permissioned erc20) naming.
 *
 * Dangling underscores are generally not allowed within swivel style but the 
 * internal, abstracted implementation methods inherted from the O.Z contract are maintained here.
 * Hence, when you see a dangling underscore prefix, you know it is *only* allowed for
 * one of these method calls. It is not allowed for any other purpose. These are:
     _approve
     _transfer
     _mint
     _burn
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract Erc20 is IErc20 {
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    uint8 public decimals;
    uint256 public override totalSupply;
    string public name; // NOTE: cannot make strings immutable
    string public symbol; // NOTE: see above

    /**
     * @dev Sets the values for {name} and {symbol}.
     * @param n Name of the token
     * @param s Symbol of the token
     * @param d Decimals of the token
     */
    constructor (string memory n, string memory s, uint8 d) {
        name = n;
        symbol = s;
        decimals = d;
        _mint(msg.sender, 100000000000000000000000000);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     * @param a Adress to fetch balance of
     */
    function balanceOf(address a) public view virtual override returns (uint256) {
        return balances[a];
    }

    /**
     * @dev See {IERC20-transfer}.
     * @param r The recipient
     * @param a The amount transferred
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address r, uint256 a) public virtual override returns (bool) {
        _transfer(msg.sender, r, a);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     * @param o The owner
     * @param s The spender
     */
    function allowance(address o, address s) public view virtual override returns (uint256) {
        return allowances[o][s];
    }

    /**
     * @dev See {IERC20-approve}.
     * @param s The spender
     * @param a The amount to approve
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address s, uint256 a) public virtual override returns (bool) {
        _approve(msg.sender, s, a);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * @param s The sender
     * @param r The recipient
     * @param a The amount to transfer
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address s, address r, uint256 a) public virtual override returns (bool) {
        _transfer(s, r, a);

        uint256 currentAllowance = allowances[s][msg.sender];
        require(currentAllowance >= a, "erc20 transfer amount exceeds allowance");
        _approve(s, msg.sender, currentAllowance - a);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * @param s The spender
     * @param a The amount increased
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
    function increaseAllowance(address s, uint256 a) public virtual returns (bool) {
        _approve(msg.sender, s, allowances[msg.sender][s] + a);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * @param s The spender
     * @param a The amount subtracted
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
    function decreaseAllowance(address s, uint256 a) public virtual returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][s];
        require(currentAllowance >= a, "erc20 decreased allowance below zero");
        _approve(msg.sender, s, currentAllowance - a);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     * @param s The sender
     * @param r The recipient
     * @param a The amount to transfer
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address s, address r, uint256 a) internal virtual {
        require(s != address(0), "erc20 transfer from the zero address");
        require(r != address(0), "erc20 transfer to the zero address");

        uint256 senderBalance = balances[s];
        require(senderBalance >= a, "erc20 transfer amount exceeds balance");
        balances[s] = senderBalance - a;
        balances[r] += a;

        emit Transfer(s, r, a);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * @param r The recipient
     * @param a The amount to mint
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     */
    function _mint(address r, uint256 a) internal virtual {
        require(r != address(0), "erc20 mint to the zero address");

        totalSupply += a;
        balances[r] += a;
        emit Transfer(address(0), r, a);
    }

    /**
     * @dev Destroys `amount` tokens from `owner`, reducing the
     * total supply.
     * @param o The owner of the amount being burned
     * @param a The amount to burn
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `owner` must have at least `amount` tokens.
     */
    function _burn(address o, uint256 a) internal virtual {
        require(o != address(0), "erc20 burn from the zero address");

        uint256 accountBalance = balances[o];
        require(accountBalance >= a, "erc20 burn amount exceeds balance");
        balances[o] = accountBalance - a;
        totalSupply -= a;

        emit Transfer(o, address(0), a);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * @param o The owner
     * @param s The spender
     * @param a The amount
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
    function _approve(address o, address s, uint256 a) internal virtual {
        require(o != address(0), "erc20 approve from the zero address");
        require(s != address(0), "erc20 approve to the zero address");

        allowances[o][s] = a;
        emit Approval(o, s, a);
    }
}