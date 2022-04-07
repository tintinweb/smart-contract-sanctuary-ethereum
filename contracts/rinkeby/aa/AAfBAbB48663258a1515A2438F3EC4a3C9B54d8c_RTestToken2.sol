// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error SwapNotEnabledYet();

contract RTestToken2 is ERC20, Ownable {

    // For team, staking, P2E ecosystem, other
    uint128 public constant INITIAL_AMOUNT_TEAM = 1_000_000_000; // 10%
    uint128 public constant INITIAL_AMOUNT_STAKING = 1_500_000_000; // 15%
    uint128 public constant INITIAL_AMOUNT_ECOSYSTEM = 2_500_000_000; // 25%
    uint128 public constant INITIAL_AMOUNT_OTHER = 5_000_000_000; // 50%
    
    address public constant ADDRESS_TEAM = 0xb09613A3e92971Db7a038BC5cDDd635Bd718cAC1;
    address public constant ADDRESS_STAKING = 0x5ecd185e32b478B4f58C5F3565FdceA3023884A1;
    address public constant ADDRESS_ECOSYSTEM = 0x331cEE12D7f2D86Bd971b03B1CF5621D54c5Bf88;
    address public constant ADDRESS_OTHER = 0x72b082925f7e51B1Acfd34425846913Be6B043B7;
    
    // For bp (bot protection), to deter liquidity sniping, enabled during first moments of each swap liquidity (ie. Uniswap, Quickswap, etc)
    uint128 public bpAllowedNumberOfTx;     // Max allowed number of buys/sells on swap during bp per address
    uint128 public bpMaxGas;                // Max gwei per trade allowed during bot protection
    uint128 public bpMaxBuyAmount;          // Max number of tokens an address can buy during bot protection
    uint128 public bpMaxSellAmount;         // Max number of tokens an address can sell during bot protection
    bool public bpEnabled;                  // Bot protection, on or off
    bool public bpTradingEnabled;           // Enables trading during bot protection period
    bool public bpPermanentlyDisabled;      // Starts false, but when set to true, is permanently true. Let's public see that it is off forever.
    address[] bpAddressTransactors;                                 // For bpAddressTimesTransacted, so we can iterate and reset all values when moving between different liquidity launches (ie. Uniswap & Quickswap together first then Pancakeswap after)
    mapping (address => bool) public bpSwapPairPools;               // ie. Uniswap V2 ETH-REMN Pool (router) for bot protected buy/sell, add after pools established. Mapped in case launching in more than one place at the same time.
    mapping (address => uint32) public bpAddressTimesTransacted;    // Mapped value counts number of times transacted (2 max per address during bp)
    mapping (address => bool) public bpBlacklisted;                 // If wallet tries to trade after liquidity is added but before owner sets trading on, wallet is blacklisted

    // GAS TEST
    uint16[] gasTestArr32;
    uint16[] gasTestArr256;
    mapping (uint16 => uint32) public gasTestMap32;
    mapping (uint16 => uint256) public gasTestMap256;

    constructor() ERC20("RTestToken2", "RTT2") {
        _mint(ADDRESS_TEAM, INITIAL_AMOUNT_TEAM * 10 ** 18);
        _mint(ADDRESS_STAKING, INITIAL_AMOUNT_STAKING * 10 ** 18);
        _mint(ADDRESS_ECOSYSTEM, INITIAL_AMOUNT_ECOSYSTEM * 10 ** 18);
        _mint(ADDRESS_OTHER, INITIAL_AMOUNT_OTHER * 10 ** 18);

        // Default values for bp (bot protection), adjustable
        bpAllowedNumberOfTx = 2;                // Max 2 buy or sell swaps (either) per wallet, during bot protection
        bpMaxGas = 501 * 10 ** 18;              // Default gwei max = 501
        bpMaxBuyAmount = 3670001 * 10 ** 18;    // Default max buy tokens = 3,670,001 (approximately 0.50% of initial circulating supply)
        bpMaxSellAmount = 3670001 * 10 ** 18;   // Default max sell tokens = 3,670,001 (approximately 0.50% of initial circulating supply)
    }

    /**
     * @dev Adds a new swap pair pool whitelist address to the bot protection.
     */
    function bpAddNewSwapPairPool(address addr) external onlyOwner {
        bpSwapPairPools[addr] = true;
    }

    /**
     * @dev Toggles bot protection, blocking suspicious transactions during liquidity events.
     */
    function bpToggleOnOff() external onlyOwner {
        bpEnabled = !bpEnabled;
    }

    /**
     * @dev Sets max gwei allowed in transaction when bot protection is on.
     */
    function bpSetMaxGwei(uint128 gweiAmount) external onlyOwner {
        bpMaxGas = gweiAmount;
    }

    /**
     * @dev Sets max buy value when bot protection is on.
     */
    function bpSetMaxBuyValue(uint128 val) external onlyOwner {
        bpMaxBuyAmount = val;
    }

     /**
     * @dev Sets max sell value when bot protection is on.
     */
    function bpSetMaxSellValue(uint128 val) external onlyOwner {
        bpMaxSellAmount = val;
    }

    /**
     * @dev Adds swap pair pool address (i.e. Uniswap V2 ETH-REMN pool, for bot protection)
     */
    function bpAddSwapPairPool(address addr) external onlyOwner {
        bpSwapPairPools[addr] = true;
    }

    /**
     * @dev Removes swap pair pool address (i.e. Uniswap V2 ETH-REMN pool, for bot protection)
     */
    function bpRemoveSwapPairPool(address addr) external onlyOwner {
        bpSwapPairPools[addr] = false;
    }

    /**
     * @dev Turns off bot protection permanently.
     */
    function bpDisablePermanently() external onlyOwner {
        bpEnabled = false;
        bpPermanentlyDisabled = true;
    }

    /**
     * @dev Toggles trading (requires bp not permanently disabled)
     */
    function bpToggleTrading() external onlyOwner {
        require(!bpPermanentlyDisabled, "Cannot toggle when bot protection is already disabled permanently");
        bpTradingEnabled = !bpTradingEnabled;
    }

    /**
     * @dev Resets transaction count of all addresses (ie. For launching on Uniswap & Quickswap at same time, then Pancakeswap later)
     */
    function bpResetAllAddressesTimesTransacted() external onlyOwner {
        for (uint32 i = 0; i < bpAddressTransactors.length; i++) {
            bpAddressTimesTransacted[bpAddressTransactors[i]] = 0;
        }
    }

    function testGasConsumation32(uint32 val) external onlyOwner {
        for (uint32 i = 0; i < 1000; i++) {
            gasTestMap32[gasTestArr32[i]] = val;
        }
    }

    function testGasConsumation256(uint256 val) external onlyOwner {
        for (uint32 i = 0; i < 1000; i++) {
            gasTestMap256[gasTestArr256[i]] = val;
        }
    }

    /**
     * @dev Check before token transfer if bot protection is on, to block suspicious transactions
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        // Bot/snipe protection requirements if bp (bot protection) is on, and is not already permanently disabled
        if (bpEnabled && !bpPermanentlyDisabled && msg.sender != owner()) {
            require(!bpBlacklisted[from] && !bpBlacklisted[to], "BP: Account is blacklisted"); // Must not be blacklisted
            require(tx.gasprice <= bpMaxGas, "BP: Gas setting exceeds allowed limit"); // Must set gas below allowed limit
        
            // If user is buying (from swap), check that the buy amount is less than the limit (this will not block other transfers unrelated to swap liquidity)
            if (bpSwapPairPools[from] == true) {
                require(amount <= bpMaxBuyAmount, "BP: Buy exceeds allowed limit"); // Cannot buy more than allowed limit
                require(bpAddressTimesTransacted[to] <= bpAllowedNumberOfTx, "BP: Exceeded number of allowed transactions");
                if (!bpTradingEnabled) {
                    bpBlacklisted[to] = true; // Blacklist wallet if it tries to trade (i.e. bot automatically trying to snipe liquidity)
                    revert SwapNotEnabledYet(); // Revert with error message
                } else {
                    bpAddressTimesTransacted[to] += 1; // User has passed transaction conditions, so add to mapping (to limit user to 2 transactions)
                }
            // If user is selling (from swap), check that the sell amount is less than the limit. The code is mostly repeated to avoid declaring variable and wasting gas.
            } else if (bpSwapPairPools[to] == true) {
                require(amount <= bpMaxSellAmount, "BP: Sell exceeds limit"); // Cannot sell more than allowed limit
                require(bpAddressTimesTransacted[from] <= bpAllowedNumberOfTx, "BP: Exceeded number of allowed transactions");
                if (!bpTradingEnabled) {
                    bpBlacklisted[from] = true; // Blacklist wallet if it tries to trade (i.e. bot automatically trying to snipe liquidity)
                    revert SwapNotEnabledYet(); // Revert with error message
                } else {
                    bpAddressTimesTransacted[from] += 1; // User has passed transaction conditions, so add to mapping (to limit user to 2 transactions)
                }
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

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