// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;
import "./wERC20R.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Bridge {
    uint256 public delayBlock = 5;
    // map erc --> rev erc
    mapping(address => address) revTokenMap;

    function getRev(address _erc20Contract) public view returns (address) {
        return revTokenMap[_erc20Contract];
    }

    struct withdrawInfo {
        uint256 amt;
        uint256 startBlock;
    }
    //map wallet --> erc20 --> withdrawinfo
    mapping(address => mapping(address => withdrawInfo)) withdrawBalance;

    function getwithdrawAmt(
        address from,
        address _erc20Contract
    ) public view returns (uint256) {
        return withdrawBalance[from][_erc20Contract].amt;
    }

    // deposit erc20 to get werc20R
    function BridgeIn(address _erc20Contract, uint256 amount) public {
        // Create a reference to the underlying asset contract, like DAI.
        ERC20 underlying = ERC20(_erc20Contract);
        // Create a reference to the corresponding rToken contract, like rDAI
        wERC20R rToken;
        if (revTokenMap[_erc20Contract] == address(0)) {
            rToken = new wERC20R(
                string(abi.encodePacked("rev", underlying.name())),
                string(abi.encodePacked("r-", underlying.symbol())),
                3,
                0x70997970C51812dc3A010C7d01b50e0d17dc79C8
            );
            revTokenMap[_erc20Contract] = address(rToken);
        } else {
            rToken = wERC20R(revTokenMap[_erc20Contract]);
        }
        underlying.transferFrom(msg.sender, address(this), amount);
        rToken.mint(msg.sender, amount);
    }

    // burn werc20R to get erc20
    function BridgeOut(address _erc20Contract, uint256 amount) public {
        require(revTokenMap[_erc20Contract] != address(0), "no such rToken");
        // Create a reference to the corresponding rToken contract, like rDAI
        wERC20R rToken = wERC20R(revTokenMap[_erc20Contract]);
        require(rToken.balanceOf(msg.sender) >= amount, "Not enough rtoken");
        rToken.burn(msg.sender, amount);

        if (withdrawBalance[msg.sender][_erc20Contract].amt == 0) {
            withdrawBalance[msg.sender][_erc20Contract].amt = amount;
        } else {
            withdrawBalance[msg.sender][_erc20Contract].amt += amount;
        }
        withdrawBalance[msg.sender][_erc20Contract].startBlock = block.number;
    }

    function withdrawERC20(address _erc20Contract, uint256 amount) public {
        require(
            block.number >=
                withdrawBalance[msg.sender][_erc20Contract].startBlock +
                    delayBlock,
            "Time (Block) doesn't pass enough yet"
        );
        require(
            withdrawBalance[msg.sender][_erc20Contract].amt >= amount,
            "withdraw amt exceeded"
        );

        ERC20 underlying = ERC20(_erc20Contract);
        withdrawBalance[msg.sender][_erc20Contract].amt -= amount;
        underlying.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-contracts/utils/Context.sol";
import "openzeppelin-contracts/utils/math/Math.sol";
import "openzeppelin-contracts/utils/math/SafeMath.sol";

// import "hardhat/console.sol";

uint256 constant NULL = 0;

contract ERC20R is Context, IERC20, IERC20Metadata {
    using AddressMappingLib for AddressMapping;
    using Math for uint256;
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public frozen;
    mapping(uint256 => mapping(address => Spenditure[])) private _spenditures;
    mapping(bytes32 => Debt[]) private _claimToDebts;
    mapping(uint256 => uint256) private _numAddressesInEpoch;
    mapping(uint256 => mapping(address => Burn[])) private _burns;

    modifier onlyGovernance() {
        require(
            msg.sender == _governanceContract,
            "ERC721R: Unauthorized call."
        );
        _;
    }

    uint256 public DELTA = 1000;
    uint256 public NUM_REVERSIBLE_BLOCKS;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address private _governanceContract;

    string private _name;
    string private _symbol;

    struct Spenditure {
        address from;
        address to;
        uint256 amount;
        uint256 blockNumber;
    }

    struct Debt {
        address from;
        address to;
        uint256 amount;
    }

    struct Burn {
        uint256 blockNumber;
        uint256 amount;
    }

    struct TopoSortInfo {
        AddressMapping addressMap;
        address[] orderedSuspects;
        uint256 susPos;
    }

    struct ObligInfo {
        AddressMapping oblig;
        address addr;
        uint256 remaining;
        AddressMapping addrToSuspectStart;
    }

    event ClearedDataInTimeblock(uint256 length, uint256 blockNum);
    event FreezeSuccessful(
        address from,
        address to,
        uint256 amount,
        uint256 blockNumber,
        uint256 index,
        bytes32 claimID
    );
    event ReverseSuccessful(bytes32 claimID);
    event ReverseRejected(bytes32 claimID);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 reversiblePeriod_,
        address governanceContract_
    ) {
        _name = name_;
        _symbol = symbol_;
        NUM_REVERSIBLE_BLOCKS = reversiblePeriod_;
        _governanceContract = governanceContract_;
    }

    /*
    OTHER REGULAR ERC20 CONTRACT FUNCTIONS (FROM OPENZEPPELIN)
    */

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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    /*
     * FREEZE AND REVERSE RELATED FUNCTIONS
     */

    /**
    Helper method for binary search for a given block number within one of the nested mappings 
    (_spenditures or _burns). Returns the index of the spenditure with the smallest block number
    that's still greater than or equal to the lowerBound argument 
     */
    function _findInternal(
        bool forSpenditures, //false if for _burns
        uint256 epoch,
        address from,
        uint256 begin,
        uint256 end,
        uint256 lowerBound
    ) private view returns (uint256 ret) {
        uint256 len = end - begin;
        if (len == 0) {
            if (
                (forSpenditures &&
                    _spenditures[epoch][from].length > begin &&
                    _spenditures[epoch][from][begin].blockNumber >=
                    lowerBound) ||
                (!forSpenditures &&
                    _burns[epoch][from].length > begin &&
                    _burns[epoch][from][begin].blockNumber >= lowerBound)
            ) {
                return begin;
            }
            return
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        uint256 mid = begin + len / 2;
        uint256 v = forSpenditures
            ? _spenditures[epoch][from][mid].blockNumber
            : _burns[epoch][from][mid].blockNumber;
        if (lowerBound < v)
            return
                _findInternal(
                    forSpenditures,
                    epoch,
                    from,
                    begin,
                    mid,
                    lowerBound
                );
        else if (lowerBound > v)
            return
                _findInternal(
                    forSpenditures,
                    epoch,
                    from,
                    mid + 1,
                    end,
                    lowerBound
                );
        else {
            while (
                mid > 0 &&
                ((forSpenditures &&
                    _spenditures[epoch][from][mid - 1].blockNumber ==
                    lowerBound) ||
                    (!forSpenditures &&
                        _burns[epoch][from][mid - 1].blockNumber == lowerBound))
            ) {
                mid--;
            }
            return mid;
        }
    }

    /**
    Helper method for freeze. In order to create arrays and maps for the suspect addresses
    in memory, we must know an approximate upper bound on the number of addresses. 
    This returns the number of suspect transactions (which is >= # suspect addresses). 
    Starting at a given spenditure s, does a DFS starting at s 
     */
    function _getMaxNumSuspects(
        Spenditure storage curr
    ) private view returns (uint256) {
        uint256 n = 0;
        (uint256 currEpoch, uint256 startIndex) = _getEpochAndIndex(curr, true);
        //go through all descendant txs from curr.to recursively (after curr.block_number)
        for (
            ;
            startIndex < _spenditures[currEpoch][curr.to].length;
            startIndex++
        ) {
            Spenditure storage s = _spenditures[currEpoch][curr.to][startIndex];
            n += _getMaxNumSuspects(s);
        }
        uint256 lastEpoch = _getEpoch(block.number);
        for (uint256 i = currEpoch + 1; i <= lastEpoch; i++) {
            for (uint256 j = 0; j < _spenditures[i][curr.to].length; j++) {
                Spenditure storage s = _spenditures[i][curr.to][j];
                n += _getMaxNumSuspects(s);
            }
        }
        return n + 1;
    }

    /**
    Helper method - 
    Given a spenditure s, return the epoch and starting index to begin iteration on descendants of s.to
     */
    function _getEpochAndIndex(
        Spenditure storage curr,
        bool forSpenditures
    ) private view returns (uint256 currEpoch, uint256 startIndex) {
        currEpoch = _getEpoch(curr.blockNumber + 1);
        startIndex = _findInternal(
            forSpenditures,
            currEpoch,
            curr.to,
            0,
            forSpenditures
                ? _spenditures[currEpoch][curr.to].length
                : _burns[currEpoch][curr.to].length,
            curr.blockNumber + 1
        );
    }

    /**
    Helper for freeze. Freeze algorithm goes through suspect addresses 
    in topological order. 
    */
    function _getTopologicalOrder(
        Spenditure storage s
    ) private view returns (TopoSortInfo memory) {
        uint256 n = _getMaxNumSuspects(s);
        //mapping from address to the block number of the first suspicious transaction
        AddressMapping memory addrToSuspectStart = AddressMapping(
            new NodeStatus[](n),
            n
        );
        //may be larger than needed
        address[] memory orderedSuspects = new address[](n);
        TopoSortInfo memory t = TopoSortInfo(
            addrToSuspectStart,
            orderedSuspects,
            0
        );
        _visit(s, t);
        return t;
    }

    /**
    Recursive helper method for _getTopologicalOrder
    DFS approach for topological sort
    modifies parameter TopoSortInfo t in-place
     */
    function _visit(
        Spenditure storage curr,
        TopoSortInfo memory t
    ) private view {
        uint256 earliestBlock = t.addressMap.get(curr.to);
        if (earliestBlock == NULL || curr.blockNumber < earliestBlock) {
            t.addressMap.put(curr.to, curr.blockNumber);
        }
        (uint256 currEpoch, uint256 startIndex) = _getEpochAndIndex(curr, true);
        //go through all descendant txs from curr.to recursively (after curr.block_number)
        for (
            ;
            startIndex < _spenditures[currEpoch][curr.to].length;
            startIndex++
        ) {
            Spenditure storage s = _spenditures[currEpoch][curr.to][startIndex];
            if (t.addressMap.get(s.to) == NULL) {
                _visit(s, t);
            }
        }
        uint256 lastEpoch = _getEpoch(block.number);
        for (uint256 i = currEpoch + 1; i <= lastEpoch; i++) {
            for (uint256 j = 0; j < _spenditures[i][curr.to].length; j++) {
                Spenditure storage s = _spenditures[i][curr.to][j];
                if (t.addressMap.get(s.to) == NULL) {
                    _visit(s, t);
                }
            }
        }
        t.orderedSuspects[t.susPos] = curr.to;
        t.susPos++;
    }

    //returns the amount burned at s.to between s.blockNumber and now.
    function _burnedSince(
        Spenditure storage s
    ) private view returns (uint256 burned) {
        burned = 0;
        (uint256 currEpoch, uint256 startIndex) = _getEpochAndIndex(s, false);
        for (; startIndex < _burns[currEpoch][s.to].length; startIndex++) {
            Burn storage b = _burns[currEpoch][s.to][startIndex];
            burned += b.amount;
        }
        uint256 lastEpoch = _getEpoch(block.number);
        for (uint256 i = currEpoch + 1; i <= lastEpoch; i++) {
            for (uint256 j = 0; j < _burns[i][s.to].length; j++) {
                Burn storage b = _burns[currEpoch][s.to][startIndex];
                burned += b.amount;
            }
        }
    }

    /**
    Helper method for freeze, accounts for inner for loop of the freeze algorithm. 
    Since burns are accounted for before this function is called, we can assume conservation 
    of funds in the ecosystem and that all obligation is passed to the children. 
     */
    function _calculateChildOblig(ObligInfo memory info) private view {
        uint256 startBlock = info.addrToSuspectStart.get(info.addr);
        uint256 firstEpoch = _getEpoch(startBlock + 1);
        uint256 startIndex = _findInternal(
            true,
            firstEpoch,
            info.addr,
            0,
            _spenditures[firstEpoch][info.addr].length,
            startBlock + 1
        );
        uint256 lastEpoch = _getEpoch(block.number);
        //Iterates through transactions in reverse chronological order
        for (
            uint256 currEpoch = lastEpoch;
            currEpoch > firstEpoch;
            currEpoch--
        ) {
            for (
                uint256 j = _spenditures[currEpoch][info.addr].length;
                j > 0;
                j--
            ) {
                Spenditure storage curr = _spenditures[currEpoch][info.addr][
                    j - 1
                ];
                uint256 ob = info.remaining.min(curr.amount);
                info.oblig.put(curr.to, info.oblig.get(curr.to) + ob);
                info.remaining -= ob;
                if (info.remaining == 0) return;
            }
        }
        for (
            uint256 j = _spenditures[firstEpoch][info.addr].length;
            j > startIndex;
            j--
        ) {
            Spenditure storage curr = _spenditures[firstEpoch][info.addr][
                j - 1
            ];
            uint256 ob = info.remaining.min(curr.amount);
            info.oblig.put(curr.to, info.oblig.get(curr.to) + ob);
            info.remaining -= ob;
            if (info.remaining == 0) return;
        }
    }

    /* Assumes no cycles in spenditures for now.
     * Can only be called by governance contract.
     * Called if judges approve the freeze request.
     */
    function freeze(
        uint256 epoch,
        address from,
        uint256 index
    ) public onlyGovernance returns (bytes32 claimID) {
        // get transaction info
        uint256 epochLength = _spenditures[epoch][from].length;
        require(
            index >= 0 && index < epochLength,
            "ERC20R: Invalid index provided."
        );
        Spenditure storage s = _spenditures[epoch][from][index];
        claimID = keccak256(abi.encode(s));

        //check if it's still reversible
        if (block.number > NUM_REVERSIBLE_BLOCKS) {
            require(
                s.blockNumber >= block.number - NUM_REVERSIBLE_BLOCKS,
                "ERC20R: specified transaction is no longer reversible."
            );
        }

        //in the future, we'd need an extra preprocessing step here for removing loops.

        TopoSortInfo memory t = _getTopologicalOrder(s);

        AddressMapping memory oblig = AddressMapping(
            new NodeStatus[](t.orderedSuspects.length),
            t.orderedSuspects.length
        );
        oblig.put(s.to, s.amount);
        //orderedSuspects is in reverse topological order, so loop backwards.
        for (uint256 addrIndex = t.susPos; addrIndex > 0; --addrIndex) {
            address addr = t.orderedSuspects[addrIndex - 1];

            uint256 toFreeze = oblig.get(addr).min(
                _balances[addr] - frozen[addr] //amount available to freeze in balance.
            );

            frozen[addr] += toFreeze;
            if (toFreeze > 0)
                _claimToDebts[claimID].push(Debt(addr, s.from, toFreeze));
            (bool zeroOrPositive, uint256 remaining) = oblig.get(addr).trySub(
                toFreeze + _burnedSince(s)
            );
            if (!zeroOrPositive || remaining == 0) {
                continue;
            }
            _calculateChildOblig(
                ObligInfo(oblig, addr, remaining, t.addressMap)
            );
        }
        //hash the spenditure; this is the claim hash now.
        emit FreezeSuccessful(
            from,
            s.to,
            s.amount,
            s.blockNumber,
            index,
            claimID
        );
    }

    /**
    Called if the judges vote to reverse the transaction. Can only be called by governance contract
    */
    function reverse(bytes32 claimID) external onlyGovernance {
        require(_claimToDebts[claimID].length > 0, "Invalid claimID.");
        //go through all of _claimToDebts[tx_va0] and transfer
        for (uint256 i = 0; i < _claimToDebts[claimID].length; i++) {
            Debt storage s = _claimToDebts[claimID][i];
            frozen[s.from] -= s.amount;
            _transfer(s.from, s.to, s.amount);
        }
        delete _claimToDebts[claimID];
        emit ReverseSuccessful(claimID);
    }

    /**
    Called if the judges disapprove the reversal. Can only be called by governance contract
    */
    function rejectReverse(bytes32 claimID) external onlyGovernance {
        require(_claimToDebts[claimID].length > 0, "Invalid claimID.");
        for (uint256 i = 0; i < _claimToDebts[claimID].length; i++) {
            Debt storage s = _claimToDebts[claimID][i];
            frozen[s.from] -= s.amount;
        }
        delete _claimToDebts[claimID];
        emit ReverseRejected(claimID);
    }

    /**
    addresses argument is calculated by reading the _spenditures and _burns structures
    from the chain. 
    It is expected that this function is called regularly to clear the contract of 
    any outdated unused storage data. 
    */
    function clean(address[] calldata addresses, uint256 epoch) external {
        require(
            block.number > NUM_REVERSIBLE_BLOCKS &&
                (epoch + 1) * DELTA - 1 < block.number - NUM_REVERSIBLE_BLOCKS,
            "ERC20-R: Block Epoch is not allowed to be cleared yet."
        );
        //requires you to clear all of it.
        require(
            _numAddressesInEpoch[epoch] == addresses.length,
            "ERC20R: Must clear the entire block Epoch's data at once."
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            //require it to have data, not empty arrary
            require(
                _spenditures[epoch][addresses[i]].length > 0 ||
                    _burns[epoch][addresses[i]].length > 0,
                "ERC20R: addresses to clean for block Epoch does not match the actual data storage."
            );
            delete _spenditures[epoch][addresses[i]];
            delete _burns[epoch][addresses[i]];
        }
        _numAddressesInEpoch[epoch] = 0;
        emit ClearedDataInTimeblock(addresses.length, epoch);
    }

    /*
     * MODIFIED ERC20 METHODS
     */

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        uint256 amountRemaining = fromBalance - amount;
        require(
            amountRemaining >= frozen[from],
            "ERC20R: Cannot spend frozen money in account."
        );

        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        uint256 epoch = block.number / DELTA;
        if (
            _spenditures[epoch][from].length == 0 &&
            _burns[epoch][from].length == 0
        ) {
            //new value stored for mapping
            _numAddressesInEpoch[epoch] += 1;
        }
        //record transaction in case of future freeze
        _spenditures[epoch][from].push(
            Spenditure(from, to, amount, block.number)
        );

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20R: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account] - frozen[account];
        require(
            accountBalance >= amount,
            "ERC20R: burn amount exceeds unfrozen balance"
        );
        unchecked {
            _balances[account] = _balances[account] - amount;
        }
        _totalSupply -= amount;
        uint256 epoch = _getEpoch(block.number);
        //update burn log
        _burns[epoch][account].push(Burn(block.number, amount));
        if (
            _spenditures[epoch][account].length == 0 &&
            _burns[epoch][account].length == 0
        ) {
            //new value stored for mapping
            _numAddressesInEpoch[epoch] += 1;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _getEpoch(uint256 blockNumber) private view returns (uint256) {
        return blockNumber / DELTA;
    }

    function getSpenditures(
        uint256 epoch,
        address from
    ) external view returns (Spenditure[] memory) {
        return _spenditures[epoch][from];
    }
}

//used for address mapping for topological sort, and oblig mapping
struct NodeStatus {
    address addr;
    uint256 val;
}

//exists because vanilla mappings can only exist in storage, but that
//is too expensive.
struct AddressMapping {
    NodeStatus[] slots;
    uint256 num_slots;
}

//library for addressmapping, for modularity
library AddressMappingLib {
    //assumes there's enough slots
    function put(
        AddressMapping memory table,
        address addr,
        uint256 val
    ) internal pure returns (AddressMapping memory) {
        uint256 i = getDefaultIndex(addr) % table.num_slots;
        while (table.slots[i].addr != address(0)) {
            if (table.slots[i].addr == addr) {
                //updating existing record
                break;
            }
            // linear probe into the next available index
            i = (i + 1) % table.num_slots;
        }
        table.slots[i].addr = addr;
        table.slots[i].val = val;
        return table;
    }

    function get(
        AddressMapping memory table,
        address addr
    ) internal pure returns (uint256) {
        uint256 def = getDefaultIndex(addr) % table.num_slots;
        uint256 i;
        bool hasIncremented = false;
        for (
            i = def;
            table.slots[i % table.num_slots].addr != address(0) && //slot isn't empty
                table.slots[i % table.num_slots].addr != addr; //haven't found a match yet
            i++
        ) {
            if (hasIncremented && i == def) return NULL; // has gone through all slots
            hasIncremented = true;
        }
        return
            table.slots[i % table.num_slots].addr == addr
                ? table.slots[i % table.num_slots].val
                : NULL;
    }

    function getDefaultIndex(address addr) private pure returns (uint256) {
        return uint256(uint160(addr));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;
import "./ERC20R.sol";

contract wERC20R is ERC20R {
    address private bridgeContract;

    // IERC20 public immutable underlying;
    constructor(
        string memory name,
        string memory symbol,
        uint256 numReversibleBlocks,
        address governanceContract
    ) ERC20R(name, symbol, numReversibleBlocks, governanceContract) {
        bridgeContract = msg.sender;
    }

    modifier onlyBridge() {
        require(
            bridgeContract == msg.sender,
            "wERC20R: only the bridge can trigger this method!"
        );
        _;
    }

    function mint(address account, uint256 amount) public virtual onlyBridge {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public virtual onlyBridge {
        _burn(account, amount);
    }
}