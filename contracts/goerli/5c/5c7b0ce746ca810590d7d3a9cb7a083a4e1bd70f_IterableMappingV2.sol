/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

/*

.___  ___.  __   __       __  ___      _______. __    __       ___       __  ___  _______    .__   __.   ______    _______   _______     _______.
|   \/   | |  | |  |     |  |/  /     /       ||  |  |  |     /   \     |  |/  / |   ____|   |  \ |  |  /  __  \  |       \ |   ____|   /       |
|  \  /  | |  | |  |     |  '  /     |   (----`|  |__|  |    /  ^  \    |  '  /  |  |__      |   \|  | |  |  |  | |  .--.  ||  |__     |   (----`
|  |\/|  | |  | |  |     |    <       \   \    |   __   |   /  /_\  \   |    <   |   __|     |  . `  | |  |  |  | |  |  |  ||   __|     \   \    
|  |  |  | |  | |  `----.|  .  \  .----)   |   |  |  |  |  /  _____  \  |  .  \  |  |____    |  |\   | |  `--'  | |  '--'  ||  |____.----)   |   
|__|  |__| |__| |_______||__|\__\ |_______/    |__|  |__| /__/     \__\ |__|\__\ |_______|   |__| \__|  \______/  |_______/ |_______|_______/    

  telegram: https://t.me/MilkyShakeNodes                                                                                                                                             

                                                                                                                                               */

// File: ..\..\node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: ..\..\node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol

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

// File: ..\..\node_modules\@openzeppelin\contracts\utils\Context.sol

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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

// File: contracts\milkyTK.sol

//product by DarthMorlis and CryptoJoe355

pragma solidity ^0.8.4;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private asdasd;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MilkShake is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    string private _name = "MilkShake";
    string private _symbol = "MSN";
    uint8 private _decimals = 9;
    bool public market_active;
    mapping (address => bool) public premarket_user;

    address payable public marketingWalletAddress = payable(0xB64394fCDcd0e4c3d73389EE79525cB141EFd28d);
    address payable public devWalletAddress = payable(0xB64394fCDcd0e4c3d73389EE79525cB141EFd28d);
    address payable public teamWalletAddress =  payable(0xB64394fCDcd0e4c3d73389EE79525cB141EFd28d);
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;

    uint256 _buyLiquidityFee = 2;
    uint256 _buyMarketingFee = 6;
    uint256 _buyDevFee = 1;
    uint256 _buyTeamFee = 1;
    
    uint256 _sellLiquidityFee = 5;
    uint256 _sellMarketingFee = 3;
    uint256 _sellDevFee = 1;
    uint256 _sellTeamFee = 1;

    uint256 _liquidityShare = 15;
    uint256 _marketingShare = 50;
    uint256 _devShare = 20;
    uint256 _teamShare = 15;

    uint256 public _totalTaxIfBuying = 10;
    uint256 public _totalTaxIfSelling = 10;
    uint256 public _totalDistributionShares = 100;

    uint256 private _totalSupply =  10_000_000 * 10**_decimals;
    uint256 public _maxTxAmount =   10000* 10**_decimals;     
    uint256 public _walletMax =     20000 * 10**_decimals;      
    uint256 private minimumTokensBeforeSwap = 1500 * 10**_decimals; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = true;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    event inSwapAndLiquifyStatus(bool p);
    event stepLiquify(bool overMinimumTokenBalanceStatus,bool inSwapAndLiquifyStatus, bool isMarketPair_sender, bool swapAndLiquifyEnabledStatus);
    event stepFee(bool p);

    event devGetBnb(uint256 amount);
    event marketingGetBnb(uint256 amount);
    event liquidityGetBnb(uint256 amount);
    event eventSwapAndLiquify(uint256 amount);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //  milky
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyDevFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellDevFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_devShare).add(_teamShare);

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;
        _balances[_msgSender()] = _totalSupply;
        premarket_user[owner()] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function activate_market(bool active) external onlyOwner {
        market_active = active;
    }
    function edit_premarket_user(address _address, bool active) external onlyOwner {
        premarket_user[_address] = active;
    }

    function setBuyTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevTax, uint256 newTeamTax) external onlyOwner() {
        _buyLiquidityFee = newLiquidityTax;
        _buyMarketingFee = newMarketingTax;
        _buyDevFee = newDevTax;
        _buyTeamFee = newTeamTax;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyDevFee);
    }

    function setSelTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevTax, uint256 newTeamFee) external onlyOwner() {
        _sellLiquidityFee = newLiquidityTax;
        _sellMarketingFee = newMarketingTax;
        _sellDevFee = newDevTax;
        _sellTeamFee = newTeamFee;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellDevFee).add(_sellTeamFee);
    }
    
    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newDevShare, uint256 newTeamShare) external onlyOwner() {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _devShare = newDevShare;
        _teamShare = newTeamShare;

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_devShare).add(_teamShare);
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function enableDisableWalletLimit(bool newValue) external onlyOwner {
       checkWalletLimit = newValue;
    }

    function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax  = newLimit;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMarketingWalletAddress(address newAddress) external onlyOwner() {
        marketingWalletAddress = payable(newAddress);
    }

    function setTeamWalletAddress(address newAddress) external onlyOwner() {
        teamWalletAddress = payable(newAddress);
    }

    function setDevWalletAddress(address newAddress) external onlyOwner() {
        devWalletAddress = payable(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address

        isWalletLimitExempt[address(uniswapPair)] = true;
        isMarketPair[address(uniswapPair)] = true;
    }


    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        emit inSwapAndLiquifyStatus(inSwapAndLiquify);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(!premarket_user[sender])
            require(market_active,"cannot trade before the market opening");

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            emit stepLiquify(overMinimumTokenBalance,!inSwapAndLiquify,!isMarketPair[sender],swapAndLiquifyEnabled);
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);    
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient])
                require(balanceOf(recipient).add(finalAmount) <= _walletMax);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;
        emit eventSwapAndLiquify(amountReceived);

        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBDev = amountReceived.mul(_devShare).div(totalBNBFee);
        uint256 amountBNBTeam = amountReceived.mul(_teamShare).div(totalBNBFee);
        uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountBNBDev).sub(amountBNBTeam);

        emit devGetBnb(amountBNBDev);
        emit marketingGetBnb(amountBNBMarketing);
        emit liquidityGetBnb(amountBNBLiquidity);

        if(amountBNBMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amountBNBMarketing);

        if(amountBNBDev > 0)
            transferToAddressETH(devWalletAddress, amountBNBDev);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    
}

// File: contracts\test.sol

//product by DarthMorlis and CryptoJoe355

pragma solidity >=0.5.0 <0.9.0;



library IterableMappingV2 {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
        mapping(address =>uint256) l1cnt;
        mapping(address =>uint256) l2cnt;
        mapping(address =>uint256) l3cnt;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index) public view returns (address){
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(Map storage map,address key,uint256 val,uint256 l1cnt,uint256 l2cnt,uint256 l3cnt) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.l1cnt[key] = l1cnt;
            map.l2cnt[key] = l2cnt;
            map.l3cnt[key] = l3cnt;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }

    function getL1Counter(Map storage map,address user) public view returns (uint256){
       return map.l1cnt[user];
    }

    function getL2Counter(Map storage map,address user) public view returns (uint256){
       return map.l2cnt[user];
    } 
    
    function getL3Counter(Map storage map,address user) public view returns (uint256){
       return map.l3cnt[user];
    }
 
    function updateL1Counter(Map storage map,address user,uint256 cntnew) public {
       map.l1cnt[user] = cntnew;
    }

    function updateL2Counter(Map storage map,address user,uint256 cntnew) public {
       map.l2cnt[user] = cntnew;
    }

    function updateL3Counter(Map storage map,address user,uint256 cntnew) public {
       map.l3cnt[user] = cntnew;
    }
}

contract NODERewardManagementV2 {
    using SafeMath for uint256;
    using IterableMappingV2 for IterableMappingV2.Map;

    IterableMappingV2.Map private nodeOwners;

    uint256 public nodePrice = 100 * 10**9; //l1
    uint256 public nodePriceL2 = 500 * 10**9; //l2
    uint256 public nodePriceL3 = 1000 * 10**9; //l3


    uint256 public rewardPerNode = 125 * 10**7;  //l1
    uint256 public rewardPerNodeL2 = 75 * 10**8; //l2
    uint256 public rewardPerNodeL3 = 1875 * 10**7; //l3


    uint256 public claimTime = 6 hours;

    address public gateKeeper;
    address public token;

    bool public autoDistri = false;
    bool public distribution = false;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;
    uint256 public lastRebase =0;

    constructor(
    ) {
        gateKeeper = msg.sender;
        lastRebase = block.timestamp;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    function setManager (address token_) external onlySentry {
        token = token_;
    }

    function distributeRewards() private returns (bool){
        distribution = true;
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        address user;
        uint256 l1=0;
        uint256 l2=0;
        uint256 l3=0;

        uint256 staked = 0;
        uint256 totalstaked = 0;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        require((lastRebase - 30 minutes) < block.timestamp, "No time passed to rebase");
        if (numberOfnodeOwners == 0) {
            return false;
        }
        for (uint256 i = 0; i < numberOfnodeOwners; i++) {
            user = nodeOwners.getKeyAtIndex(i);
            l1 = nodeOwners.getL1Counter(user);
            l2 = nodeOwners.getL2Counter(user);
            l3 = nodeOwners.getL3Counter(user);
            staked = nodeOwners.get(user);
            staked += l1*rewardPerNode + l2*rewardPerNodeL2 + l3*rewardPerNodeL3;
            nodeOwners.set(user,staked,l1,l2,l3);
            totalstaked += staked;
        }
        distribution = false;
        totalRewardStaked = totalstaked;
        lastRebase = block.timestamp + claimTime;
        return true;
    }

    function distributeRewardsIDX(uint256 idx1,uint256 idx2) private returns (bool){
        distribution = true;
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        address user;
        uint256 l1=0;
        uint256 l2=0;
        uint256 l3=0;

        uint256 staked = 0;
        uint256 totalstaked;

        if(idx1 == 0){
            totalstaked = 0;
        }else {
            totalstaked = totalRewardStaked;
        }
        
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        require((lastRebase - 30 minutes) < block.timestamp);

        if (numberOfnodeOwners == 0) {
            return false;
        }
        for (uint256 i = idx1; i < idx2; i++) {
            user = nodeOwners.getKeyAtIndex(i);
            l1 = nodeOwners.getL1Counter(user);
            l2 = nodeOwners.getL2Counter(user);
            l3 = nodeOwners.getL3Counter(user);
            staked = nodeOwners.get(user);
            staked += l1*rewardPerNode + l2*rewardPerNodeL2 + l3*rewardPerNodeL3;
            nodeOwners.set(user,staked,l1,l2,l3);
            totalstaked += staked;
        }
        distribution = false;
        totalRewardStaked = totalstaked;
        lastRebase = block.timestamp + claimTime;
        return true;
    }

    function createNodeV2(address account, uint256 l,uint256 cnt) external onlySentry {
       
        uint aux = 0;
        if (!nodeOwners.inserted[account]) {
           nodeOwners.set(account,0,0,0,0);
        }

        if(l == 1){
           aux = nodeOwners.getL1Counter(account) +cnt;
           nodeOwners.updateL1Counter(account,aux);
        }else if(l == 2){
           aux = nodeOwners.getL2Counter(account) +cnt;
           nodeOwners.updateL2Counter(account,aux);
        }else {
           aux = nodeOwners.getL3Counter(account) +cnt;
           nodeOwners.updateL3Counter(account,aux);
        }
        totalNodesCreated+=cnt;
    }

    function _burn(address account,uint256 l) public onlySentry {
        uint cnt = 0;

        if(l == 1){
           cnt = nodeOwners.getL1Counter(account) -1;
           nodeOwners.updateL1Counter(account,cnt);
        }else if(l == 2){
           cnt = nodeOwners.getL2Counter(account) -1;
           nodeOwners.updateL2Counter(account,cnt);
        }else {
           cnt = nodeOwners.getL3Counter(account) -1;
           nodeOwners.updateL3Counter(account,cnt);
        }
        totalNodesCreated--;
    }

    function _cashoutAllNodesReward(address account) external onlySentry {
        uint256 l1=nodeOwners.getL1Counter(account);
        uint256 l2=nodeOwners.getL2Counter(account);
        uint256 l3=nodeOwners.getL3Counter(account);

        nodeOwners.set(account,0,l1,l2,l3);  
    }

    function _getRewardAmountOf(address account) external view returns (uint256){
        return nodeOwners.get(account);
    }

    function _getL1Counter(address account) external view returns (uint256) {
        return nodeOwners.getL1Counter(account);
    }

    function _getL2Counter(address account) external view returns (uint256) {
        return nodeOwners.getL2Counter(account);
    }

    function _getL3Counter(address account) external view returns (uint256) {
        return nodeOwners.getL3Counter(account);
    }

    function _getNodeHolders() external view returns (uint256) {
        return nodeOwners.keys.length;
    }

    function _changeNodePriceL1(uint256 newNodePrice) external onlySentry {
        nodePrice = newNodePrice;
    }

    function _changeNodePriceL2(uint256 newNodePrice) external onlySentry {
        nodePriceL2 = newNodePrice;
    }

    function _changeNodePriceL3(uint256 newNodePrice) external onlySentry {
        nodePriceL3 = newNodePrice;
    }

    function _changeRewardPerNodeL1(uint256 newPrice) external onlySentry {
        rewardPerNode = newPrice;
    }

    function _changeRewardPerNodeL2(uint256 newPrice) external onlySentry {
        rewardPerNodeL2 = newPrice;
    }

    function _changeRewardPerNodeL3(uint256 newPrice) external onlySentry {
        rewardPerNodeL3 = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }


    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.getL1Counter(account) > 0 ||  nodeOwners.getL2Counter(account) > 0 ||  nodeOwners.getL3Counter(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _distributeRewards() external  onlySentry returns (bool) {
        return distributeRewards();
    }

    function _distributeRewardsIDX(uint256 idx1,uint256 idx2) external  onlySentry returns (bool) {
        return distributeRewardsIDX(idx1,idx2);
    }
}


contract MilkyNodesManager is Ownable{

    MilkShake  milky;
    using SafeMath for uint256;

    NODERewardManagementV2 public nodeRewardManager;

    address public distributionPool;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 nodeL1Limit = 5;
    uint256 nodeL2Limit = 5;
    uint256 nodeL3Limit = 5;


    event CreateL1(address indexed owner);
    event CreateL2(address indexed owner);
    event CreateL3(address indexed owner);
    event Cashout(address indexed owner);

    bool public migration = false;


    constructor(
        address distribution,
        address payable milky_address
    ) {
        milky = MilkShake(milky_address);
        distributionPool = distribution;
    }
    
    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManager = NODERewardManagementV2(nodeManagement);
    }

    /*
    * updates
    */

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function changeNodePriceL1(uint256 newNodePrice) public onlyOwner {
        nodeRewardManager._changeNodePriceL1(newNodePrice);
    }

    function changeNodePriceL2(uint256 newNodePrice) public onlyOwner {
        nodeRewardManager._changeNodePriceL2(newNodePrice);
    }

    function changeNodePriceL3(uint256 newNodePrice) public onlyOwner {
        nodeRewardManager._changeNodePriceL3(newNodePrice);
    }

    function changeRewardPerNodeL1(uint256 newPrice) public onlyOwner {
        nodeRewardManager._changeRewardPerNodeL1(newPrice);
    }

    function changeRewardPerNodeL2(uint256 newPrice) public onlyOwner {
        nodeRewardManager._changeRewardPerNodeL2(newPrice);
    }

    function changeRewardPerNodeL3(uint256 newPrice) public onlyOwner {
        nodeRewardManager._changeRewardPerNodeL3(newPrice);
    }

    function changeClaimTime(uint256 newTime) public onlyOwner {
        nodeRewardManager._changeClaimTime(newTime);
    }

    function changeL1Limit(uint256 newLimit) public onlyOwner {
        nodeL1Limit = newLimit;
    }

    function changeL2Limit(uint256 newLimit) public onlyOwner {
        nodeL2Limit = newLimit;
    }

    function changeL3Limit(uint256 newLimit) public onlyOwner {
        nodeL3Limit = newLimit;
    }




    /*
    * buy nodes
    */

    function approveNodeL1(uint256 cnt) public {
        uint256 aux = nodeRewardManager.nodePrice() * cnt;
        milky.approve(address(this),aux);
    }
    function approveNodeL2(uint256 cnt) public {
        uint256 aux = nodeRewardManager.nodePriceL2() * cnt;
        milky.approve(msg.sender,aux);
    }
    function approveNodeL3(uint256 cnt) public {
        uint256 aux = nodeRewardManager.nodePriceL3() * cnt;
        milky.approve(msg.sender,aux);
    }


    function createNodeWithTokensL1(uint256 cnt) public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(
            sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 nodePrice = nodeRewardManager.nodePrice()*cnt;
        require(
            milky.balanceOf(sender) >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );

        require(getNodeNumberOfL1(msg.sender) <= nodeL1Limit, "NODE CREATION: Reached node Limit");
        require(getNodeNumberOfL1(msg.sender) + cnt <= nodeL1Limit, "NODE CREATION: Creation Reaches node Limit");


        milky.transferFrom(msg.sender, distributionPool, nodePrice);
        nodeRewardManager.createNodeV2(sender,1,cnt);
        emit CreateL1(sender);
    }

    function createNodeWithTokensL2(uint256 cnt) public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(
           sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 nodePriceL2 = nodeRewardManager.nodePriceL2() * cnt;
        require(
            milky.balanceOf(sender) >= nodePriceL2,
            "NODE CREATION: Balance too low for creation."
        );
        require(getNodeNumberOfL2(msg.sender) <= nodeL2Limit,"NODE CREATION: Reached node Limit");
        require(getNodeNumberOfL2(msg.sender) + cnt <= nodeL2Limit, "NODE CREATION: Creation Reaches node Limit");


        milky.transferFrom(sender, distributionPool, nodePriceL2);
        nodeRewardManager.createNodeV2(sender, 2,cnt);
        emit CreateL2(sender);
    }

    function createNodeWithTokensL3(uint256 cnt) public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(
            sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 nodePriceL3 = nodeRewardManager.nodePriceL3() * cnt;
        require(
            milky.balanceOf(sender) >= nodePriceL3,
            "NODE CREATION: Balance too low for creation."
        );
        require(getNodeNumberOfL3(msg.sender) <= nodeL3Limit, "NODE CREATION: Reached node Limit");
        require(getNodeNumberOfL3(msg.sender) + cnt <= nodeL3Limit, "NODE CREATION: Creation Reaches node Limit");

        milky.transferFrom(sender, distributionPool, nodePriceL3);
        nodeRewardManager.createNodeV2(sender,3,cnt);
        emit CreateL3(sender);
    }


    function airdropNode(address user, uint256 tier,uint256 cnt) public onlyOwner{
        nodeRewardManager.createNodeV2(user,tier,cnt);
    } 

    function cashoutAll() public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(
            sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );

        milky.transferFrom(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutAllNodesReward(sender);
        emit Cashout(sender);
    }

    function distributeRewards() public onlyOwner returns (bool) {
        return nodeRewardManager._distributeRewards();
    }

    function publiDistriRewards() public {
        nodeRewardManager._distributeRewards();
    }

    function publiDistriRewardsIDX(uint256 idx1, uint256 idx2) public {
        nodeRewardManager._distributeRewardsIDX(idx1,idx2);
    }


    /*
    *   getters
    */

    function getNodeNumberOf(address account) public view returns (uint256) {
         require(
            nodeRewardManager._isNodeOwner(account),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getL1Counter(account) +  nodeRewardManager._getL2Counter(account) + nodeRewardManager._getL3Counter(account);
    }

    function getNodeNumberOfL1(address account) public view returns (uint256) {
        return nodeRewardManager._getL1Counter(account);
    }

    function getNodeNumberOfL2(address account) public view returns (uint256) {
        return nodeRewardManager._getL2Counter(account);
    }
    function getNodeNumberOfL3(address account) public view returns (uint256) {
        return nodeRewardManager._getL3Counter(account);
    }

    function getRewardAmountOf(address account) public view onlyOwner returns (uint256) {
        return nodeRewardManager._getRewardAmountOf(account);
    }

    function getRewardAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(
            nodeRewardManager._isNodeOwner(_msgSender()),
            "NO NODE OWNER"
        );
        return nodeRewardManager._getRewardAmountOf(_msgSender());
    }


    function getNodePriceL1() public view returns (uint256) {
        return nodeRewardManager.nodePrice();
    }

    function getNodePriceL2() public view returns (uint256) {
        return nodeRewardManager.nodePriceL2();
    }

    function getNodePriceL3() public view returns (uint256) {
        return nodeRewardManager.nodePriceL3();
    }

    function getRewardPerNodeL1() public view returns (uint256) {
        return nodeRewardManager.rewardPerNode();
    }

    function getRewardPerNodeL2() public view returns (uint256) {
        return nodeRewardManager.rewardPerNodeL2();
    }

    function getRewardPerNodeL3() public view returns (uint256) {
        return nodeRewardManager.rewardPerNodeL3();
    }
    

    function getL1Limit() public view returns (uint256) {
        return nodeL1Limit;
    }

    function getL2Limit() public view returns (uint256) {
        return nodeL2Limit;
    }
    
    function getL3Limit() public view returns (uint256) {
        return nodeL3Limit;
    }


    function getClaimTime() public view returns (uint256) {
        return nodeRewardManager.claimTime();
    }

    function getTotalStakedReward() public view returns (uint256) {
        return nodeRewardManager.totalRewardStaked();
    }

    function getTotalCreatedNodes() public view returns (uint256) {
        return nodeRewardManager.totalNodesCreated();
    }

    function getNextRebase() public view returns (uint256) {
        return nodeRewardManager.lastRebase();
    }

    function getNodeHolders() public view returns (uint256) {
        return nodeRewardManager._getNodeHolders();
    }


}