// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol"; //do not need for solidity version >= 0.8.0
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDCoin.sol";
import "./EURCoin.sol";
import "./interfaces/IDEX.sol";

contract DEX is Ownable, IDEX {
    address public admin;
     
    //USDCoin, make sure to change this to your liking
    USDCoin private usdc_token;
    
    //EURCoin, make sure to change this to your liking
    EURCoin private eurc_token;

    // Liquidity pool for the exchange
    uint public usdc_reserves = 0;
    uint public eurc_reserves = 0;
    
    /*
    track which users have contributed additional liquidity to the pool
    map address to USDC amount to keep track of liquidity provided in USDC; 
    an equal value is also provided in EURC, but only USDC is tracked
    */
    mapping(address => uint) public liquidity;
    uint accumluated_fees = 0; // USD

    // Constant: x * y = k
    uint public k;
    
    // Uniswap uses 0.3% liquidity provider fee
    uint private swap_fee_numerator = 10; //1.0%
    uint private swap_fee_denominator = 1000;
    
    // EVENTS
    event AddLiquidity(address from, uint amount);
    event RemoveLiquidity(address to, uint amount);
    //define new event for sending / receiving remittances
    event SendRemittance(address from, address to, uint amount);

    constructor(address usdc_addr, address eurc_addr) Ownable() {
        admin = msg.sender;
        eurc_token = EURCoin(eurc_addr);
        usdc_token = USDCoin(usdc_addr);
    }

    function init(uint amountUSDC, uint amountEURC) override public payable {
        require(usdc_reserves==0, "DEX init(): exchange already has liquidity!");
        require(eurc_reserves==0, "DEX init(): exchange already has liquidity!");

        //transfer coins to DEX
        usdc_token.transferFrom(msg.sender, address(this), amountUSDC);
        eurc_token.transferFrom(msg.sender, address(this), amountUSDC);

        usdc_reserves = amountUSDC;
        eurc_reserves = amountEURC;
        k = usdc_reserves * eurc_reserves;
    }

    function getUserLiquidityUSDC() override public view returns (uint) {
        uint usdc_liquidity = liquidity[msg.sender];
        return usdc_liquidity;
    }

    function getUserLiquidityEURC() override public view returns (uint) {
        uint usdc_liquidity = liquidity[msg.sender];
        uint eurc_liquidity =  (usdc_liquidity * eurc_reserves) / usdc_reserves;
        return eurc_liquidity;
    }

    function getTotalFees() public view returns (uint) {
        uint usdc_liquidity = liquidity[msg.sender];
        uint usdc_fees = (accumluated_fees * usdc_liquidity) / (usdc_reserves);
        return usdc_fees;
    }
    
    function getUserFeesUSDC() public view returns (uint) {
        uint usdc_liquidity = liquidity[msg.sender];
        uint usdc_fees = (accumluated_fees * usdc_liquidity) / (2*usdc_reserves);
        return usdc_fees;
    }

    function getUserFeesEURC() public view returns (uint) {
        uint usdc_liquidity = liquidity[msg.sender];
        uint usdc_fees = (accumluated_fees * usdc_liquidity) / (2*usdc_reserves);
        uint eurc_fees = (usdc_fees * eurc_reserves) / usdc_reserves;
        return eurc_fees;
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset, not including fees or slippage
    function spotPrice(uint amountA, uint reserveA, uint reserveB) public pure override returns (uint amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = amountA * (reserveB / reserveA);
    }

    //Returns the price of input token in terms of output tokens
    function price(uint amountIn, uint reserveIn, uint reserveOut) public view override returns (uint) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * (swap_fee_denominator-swap_fee_numerator);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * swap_fee_denominator) + amountInWithFee;
        uint amountOut = numerator / denominator;
        return amountOut;
    }

    //swaps USDC to EURC and transfers to another user
    function remitUSDToEUR(address from, address to, uint amountUSDC) public override {
        uint amountEURC = swapUSDCForEURC(amountUSDC);
        eurc_token.transferFrom(from, to, amountEURC);
        emit SendRemittance(from, to, amountUSDC);
    }

    //swaps EURC to USDC and transfers to another user
    function remitEURCToUSDC(address from, address to, uint amountEURC) public override {
        uint amountUSDC = swapUSDCForEURC(amountEURC);
        usdc_token.transferFrom(from, to, amountUSDC);
        emit SendRemittance(from, to, amountUSDC);
    }

    // swap msg.sender() USDC for DEX EURC
    function swapUSDCForEURC(uint amountUSDC) public override returns (uint) {
        require(amountUSDC > 0, "INSUFFICIENT USDC");
        require(eurc_reserves > 0, "INSUFFICIENT EURC LIQUIDITY");
        require(usdc_token.transferFrom(msg.sender, address(this), amountUSDC)); //transfer USDC tokens from msg.sender to DEX
        uint fee_usdc = (amountUSDC * swap_fee_numerator) / swap_fee_denominator;
        accumluated_fees += fee_usdc; //add fee to global variable
        uint256 EURC_bought = price(amountUSDC, usdc_reserves, eurc_reserves); // price(uint amountIn, uint reserveIn, uint reserveOut)
        require(eurc_token.transfer(msg.sender, EURC_bought)); //transfer EURC tokensfrom DEX to msg.sender
        _checkRounding();

        usdc_reserves += amountUSDC;
        eurc_reserves -= EURC_bought;
        k = usdc_reserves * eurc_reserves;
        
        return EURC_bought;
    }

    // swap msg.sender() EURC for DEX USDC
    function swapEURCForUSDC(uint amountEURC) public override returns (uint) {
        require(amountEURC > 0, "INSUFFICIENT EURC");
        require(usdc_reserves > 0, "INSUFFICIENT USDC LIQUIDITY");
        require(eurc_token.transferFrom(msg.sender, address(this), amountEURC)); //transfer EURC tokens from msg.sender to DEX
        uint amountUSDC = spotPrice(amountEURC, eurc_reserves, usdc_reserves);
        uint fee_usdc = (amountUSDC * swap_fee_numerator) / swap_fee_denominator;
        accumluated_fees += fee_usdc; //add fee to global variable
        uint256 USDC_bought = price(amountEURC, eurc_reserves, usdc_reserves); // price(uint amountIn, uint reserveIn, uint reserveOut)
        require(usdc_token.transfer(msg.sender, USDC_bought)); //transfer USDC tokensfrom DEX to msg.sender
        _checkRounding();

        eurc_reserves += amountEURC;
        usdc_reserves -= USDC_bought;
        k = usdc_reserves * eurc_reserves;
        return USDC_bought;
    }

    /** 
     * Checks that users are not able to get "free money" due to rounding errors.
     *
     * A liquidity provider should be able to input more (up to 1) tokens than they are theoretically
     * entitled to, and should be able to withdraw less (up to -1) tokens then they are entitled to.
     *
     * Checks for Math.abs(token_reserves * eth_reserves - k) < (token_reserves + eth_reserves + 1));
     * to account for the small decimal errors during uint division rounding.
     */
    function _checkRounding() private {
        uint check = usdc_reserves * eurc_reserves;
        if (check >= k) {
            check = check - k;
        }
        else {
            check = k - check;
        }
        assert(check < (usdc_reserves + eurc_reserves + 1));
        k = usdc_reserves * eurc_reserves;             // reset k due to small rounding errors
    }

    /**
     * Adds liquidity given a supply of ETH (sent to the contract as msg.value).
     *
     * Calculates the liquidity to be added based on what was sent in and the prices. If the
     * caller possesses insufficient tokens to equal the ETH sent, then the transaction must
     * fail. A successful transaction should update the state of the contract, including the
     * new constant product k, and then Emit an AddLiquidity event.
     */
    function addLiquidity(uint amountUSDC) 
        external 
        payable
        override
    {        
        uint amountEURC = (amountUSDC * eurc_reserves) / usdc_reserves;
        //require sufficient USDC and EURC balance of msg.sender (must be > 0)
        require(usdc_token.balanceOf(msg.sender)>=amountUSDC, "Insufficient user USDC balance");
        require(eurc_token.balanceOf(msg.sender)>=amountEURC, "Insufficient user EURC balance");
        //transfer tokens to DEX (requires approval)
        require(usdc_token.transferFrom(msg.sender, address(this), amountUSDC), "addLiquidity: transferFrom USDC failure");
        require(eurc_token.transferFrom(msg.sender, address(this), amountEURC), "addLiquidity: transferFrom EURC failure");

        //adjust liquidity and reserves
        liquidity[msg.sender] += amountUSDC; 
        usdc_reserves += amountUSDC;
        eurc_reserves += amountEURC;

        //update k
        k = usdc_reserves * eurc_reserves; 
        emit AddLiquidity(msg.sender, amountUSDC);
    }


    /**
     * Removes liquidity given the desired amount of ETH to remove.
     *
     * Calculates the amount of your tokens that should be also removed. If the caller is not
     * entitled to remove the desired amount of liquidity, the transaction should fail. A
     * successful transaction should update the state of the contract, including the new constant
     * product k, transfer the ETH and Token to the sender and then Emit an RemoveLiquidity event.
     */
    function removeLiquidity(uint amountUSDC)
        public 
        payable
        override
    {
        //equal value of eurc liquidity to remove
        uint amountEURC = (amountUSDC * eurc_reserves) / usdc_reserves;
        require(liquidity[msg.sender]>=amountUSDC, "Cannot withdraw more liquidity than initially provided");
        require(usdc_reserves >= amountUSDC, "Insufficient user USDC reserves");
        require(eurc_reserves >= amountEURC, "Insufficient user EURC reserves");

        //calculate fees owed to msg.sender
        uint usdc_fees = (accumluated_fees * amountUSDC) / (2*usdc_reserves);
        uint eurc_fees = (usdc_fees * eurc_reserves) / usdc_reserves;

        //transfer liquidity + fees to msg.sender
        usdc_token.transfer(msg.sender, amountUSDC + usdc_fees);
        eurc_token.transfer(msg.sender, amountEURC + eurc_fees);

        //adjust liquidity and reserves
        liquidity[msg.sender] -= amountUSDC; 
        accumluated_fees -= 2*usdc_fees;
        usdc_reserves -= amountUSDC;
        eurc_reserves -= amountEURC;

        //update k
        k = usdc_reserves * eurc_reserves;
        emit RemoveLiquidity(msg.sender, amountUSDC);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract EURCoin is ERC20Burnable, Ownable {
    
    constructor() ERC20("EURCoin", "EURC") Ownable() {}

    function _mint(uint amount) 
        public 
        // onlyOwner
    {
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

interface IDEX {
    function init(uint amountUSDC, uint amountEURC)
        external
        payable;

    function spotPrice(uint amountA, uint reserveA, uint reserveB)
        external
        pure
        returns (uint amountB);

    function price(uint amountIn, uint reserveIn, uint reserveOut)
        external
        view
        returns (uint);

    function remitUSDToEUR(address from, address to, uint amountUSDC) external;

    function remitEURCToUSDC(address from, address to, uint amountEURC) external;

    function swapUSDCForEURC(uint amountUSDC)
        external
        returns (uint);

    function swapEURCForUSDC(uint amountEURC)
        external
        returns (uint);

    function getUserLiquidityUSDC()
        external
        view
        returns (uint);

    function getUserLiquidityEURC()
        external
        view
        returns (uint);

    function addLiquidity(uint amountUSDC)
        external
        payable;

    function removeLiquidity(uint amountUSDC)
        external
        payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract USDCoin is ERC20Burnable, Ownable {
    
    constructor() ERC20("USDCoin", "USDC") Ownable() {}

    function _mint(uint amount) 
        public 
        // onlyOwner
    {
        _mint(msg.sender, amount);
    }
}