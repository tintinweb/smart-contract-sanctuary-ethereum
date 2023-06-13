/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

/*
Yo fam, We created this token to give you a shot at financial freedom, 
but let's keep it real, there are risks in this game. 
Crypto is a wild ride, but here to help you up your hustle, volatility can be crazy, 
build community, stay strong and don't get lazy. 
Protect your gains and remember that family is more important than anything you can do here.  
Do your due diligence and chase that paper responsibly, Embrace the risks, 
but don't lose sight of the opportunities. 
Best of luck to you.
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: Water.sol

pragma solidity ^0.8.18;

/*
Here's a list of Libraries imported above:

* "@openzeppelin/contracts/token/ERC20/ERC20.sol";
* "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
* "@openzeppelin/contracts/token/ERC20/IERC20.sol";
* "@openzeppelin/contracts/access/Ownable.sol";
* "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
* "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


input addresses for testing: 

devWallet: 0x49FBC4AD54E592556510A6C5D3d113F1aD255256
deadWallet: 0x000000000000000000000000000000000000dEaD

USDT/BUSD tokenAddress BNB Testnet: 0xaB1a4d4f1D656d2450692D237fdD6C7f9146e814
partnershipTokenAddress BNB Testnet: 0x5e4467517AAc8F89DD3547e7B8FAfB723e270Fd0
V2Router on BNB Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1


BUSD tokenAddress ETH Testnet: 0x4c49acC40aC6C32B9Ab271027bE228D5b09d2100
PartnershipTokenAddress on ETH Testnet: 0x96c0ca1a8E9d5903D9d748533A737079308C70A6
V2Router on ETH Testnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

*/

contract ChecksSwap is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public maxWalletAmount;

    // Whitelist excludes from fees exchangeWhitelist excludes from fees and maxWallet limitations
    mapping(address => bool) private whitelist;
    mapping(address => bool) private exchangeWhitelist;
    mapping(address => bool) private maxWalletExcluded;

    mapping (address => uint256) private _balances;


    // balances for each tax category
    uint256 private devFeeBalance;
    uint256 private partnershipsBalance;
    uint256 private autoBurnBalance;
    uint256 private maintenanceBalance;

    uint256 private liquidityThreshold;

    struct Tax {
        uint256 devFee;
        uint256 partnerships;
        uint256 autoBurn;
        uint256 maintenance;
    }

    Tax public buyTax;
    Tax public sellTax;

    address private _devWallet = 0x49FBC4AD54E592556510A6C5D3d113F1aD255256;
    address private _partnershipTokenAddress = 0x96c0ca1a8E9d5903D9d748533A737079308C70A6; //partnership tokens are bought and burned
    //USDT is used to set a swapping threashold to automate tax utilization

    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 private _totalBurnedTokens;
    uint256 private _burnedTokensLast24Hours;
    uint256 private _burnStartTime;

    bool public tradingEnabled = false;
    bool inSwap = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwnerOrContract() {
        require(msg.sender == owner() || msg.sender == address(this), "Caller is not the owner or the contract");
        _;
    }

    string private _website;
    string private _twitter;
    string private _telegram;
    string private _basedDevMessage;

    event Burn(address indexed burner, uint256 amount);
    event TokensRemoved(address indexed token, address indexed operator, uint256 amount);
    event SwapFailure(string reason);

    constructor() ERC20("ChecksSwap", "CK2") {

        uint256 totalSupply = 100000000000 * (10 ** uint256(decimals()));
        _mint(msg.sender, totalSupply);
        maxWalletAmount = (totalSupply * 2) / 100;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        maxWalletExcluded[deadWallet] = true; 
        
        exchangeWhitelist[owner()] = true;
        exchangeWhitelist[address(this)] = true;
        exchangeWhitelist[uniswapV2Pair] = true;
        
        whitelist[_devWallet] = true;

        liquidityThreshold = (totalSupply * 75) / 100000; // 0.00075 of the total supply

        // After Launch taxes can be adjusted
        uint256 buyTaxTotal = 10; // devFee %, partnerships %, maintenance %, autoBurn % combined 
        uint256 sellTaxTotal = 15; // devFee %, partnerships %, autoBurn %, maintenance % combined

        require(buyTaxTotal <= 10, "Total buy tax can't exceed 10%");
        require(sellTaxTotal <= 15, "Total sell tax can't exceed 15%");

        buyTax = Tax({
            devFee: 6,       
            partnerships: 2, 
            maintenance: 1,  
            autoBurn: 1      
        });

        sellTax = Tax({
            devFee: 8,       
            partnerships: 5, 
            autoBurn: 1,     
            maintenance: 1   
        });

    }


        // Fallback function to receive Ether
            receive() external payable {}

    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external onlyOwner {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

//Allows for Removal of liquidity if the contract is holding more tokens than originally added to the pool
    function approveRouterMax() external onlyOwner {
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function removeLiquidity() external onlyOwner {
        this.approveRouterMax();
        IERC20 liquidityToken = IERC20(uniswapV2Pair);
        uint256 balance = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(uniswapV2Router), balance);
        uniswapV2Router.removeLiquidityETH(
            address(this),
            balance,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function transferTokensToContract(uint256 amount) external onlyOwner {
        _transfer(msg.sender, address(this), amount);
    }


    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }


    function setAddresses(address devWallet, address partnershipTokenAddress) public onlyOwner {
        _devWallet = devWallet;
        _partnershipTokenAddress = partnershipTokenAddress;
    }

    function getWalletAddresses() public view returns (address devWallet, address partnershipTokenAddress) {
        return (_devWallet, _partnershipTokenAddress);
    }


// Whitelist management functions
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function isWhitelisted(address _address) external view returns(bool) {
        return whitelist[_address];
    }

    // Exchange whitelist management functions
    function addToExchangeWhitelist(address _address) external onlyOwner {
        exchangeWhitelist[_address] = true;
        whitelist[_address] = true;
    }

    function removeFromExchangeWhitelist(address _address) external onlyOwner {
        exchangeWhitelist[_address] = false;
        whitelist[_address] = false;
    }

    function isExchangeWhitelisted(address _address) external view returns(bool) {
        return exchangeWhitelist[_address];
    }

    
    function setBuyTax(uint256 devFee, uint256 partnerships, uint256 maintenance, uint256 autoBurn) external onlyOwner {
        uint256 total = devFee + partnerships + maintenance + autoBurn;
        require(total <= 10, "Total buy tax can't exceed 10%");
        buyTax = Tax(devFee, partnerships, autoBurn, maintenance);
    }

    function setSellTax(uint256 devFee, uint256 partnerships, uint256 autoBurn, uint256 maintenance) external onlyOwner {
        uint256 total = devFee + partnerships + autoBurn + maintenance;
        require(total <= 15, "Total sell tax can't exceed 15%");
        sellTax = Tax(devFee, partnerships, autoBurn, maintenance);
    }

    function getTaxBalances() public view returns (uint256 _devFeeBalance, uint256 _partnershipsBalance, uint256 _autoBurnBalance, uint256 _maintenanceBalance) {
        _devFeeBalance = devFeeBalance;
        _partnershipsBalance = partnershipsBalance;
        _autoBurnBalance = autoBurnBalance;
        _maintenanceBalance = maintenanceBalance;
    }


    function setBasedDev(string calldata message) external onlyOwner {
        _basedDevMessage = message;
    }

    function BasedDev() public view returns (string memory) {
        return _basedDevMessage;
    }

    function setDYOR(string calldata website, string calldata twitter, string calldata telegram) external onlyOwner {
        _website = website;
        _twitter = twitter;
        _telegram = telegram;
    }

    function DYOR() public view returns (string memory website, string memory twitter, string memory telegram) {
        return (_website, _twitter, _telegram);
    }

    function removeTokens(IERC20 token, uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens in contract");
        token.transfer(msg.sender, amount);
        emit TokensRemoved(address(token), msg.sender, amount);
    }

    function burnedTokensTracker() public view returns (uint256 totalBurned, uint256 burnedLast24Hours) {
        return (_totalBurnedTokens, _burnedTokensLast24Hours);
    }

    function burn(uint256 amount) public {
        uint256 scaledAmount = amount * 1e18; // scale the amount according to the token decimals
        require(balanceOf(msg.sender) >= scaledAmount, "Burn amount exceeds balance");
        _transfer(msg.sender, deadWallet, scaledAmount);

        emit Burn(msg.sender, scaledAmount);

        // Update the total burned tokens
        _totalBurnedTokens += scaledAmount;

        // Check if the 24-hour period has elapsed since the last burn
        if (block.timestamp >= _burnStartTime + 1 days) {
        _burnedTokensLast24Hours = scaledAmount;
        _burnStartTime = block.timestamp;
        } else {
            _burnedTokensLast24Hours += scaledAmount;
        }
    }

//internal burn 
    function _burn(uint256 amount) private {
        require(balanceOf(address(this)) >= amount, "Burn amount exceeds balance");
        _transfer(address(this), deadWallet, amount); // Use 'deadWallet'

        emit Burn(address(this), amount);

        // Update the total burned tokens
        _totalBurnedTokens += amount;

        // Check if the 24-hour period has elapsed since the last burn
        if (block.timestamp >= _burnStartTime + 1 days) {
            _burnedTokensLast24Hours = amount;
            _burnStartTime = block.timestamp;
        } else {
            _burnedTokensLast24Hours += amount;
        }
    }

    function _swapTokensForETH(uint256 tokenAmount, address to) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uint256 initialBalance = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance;
        uint256 balanceDifference = newBalance - initialBalance;

        (bool success,) = to.call{value: balanceDifference}("");
        require(success, "Failed to send Ether");

        return balanceDifference;
    }

    function _swapETHForPartnershipTokens(uint256 ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _partnershipTokenAddress;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, 
            path,
            address(this), 
            block.timestamp
        );
    }


   function addToTaxBalance(uint256 amount) external onlyOwner {
        uint256 amountWithDecimals = amount * 10**18;
        require(balanceOf(msg.sender) >= amountWithDecimals, "Insufficient balance");
        _transfer(msg.sender, address(this), amountWithDecimals);
        uint256 distribution = amountWithDecimals / 4;

        devFeeBalance += distribution;
        partnershipsBalance += distribution;
        // Add remainder to autoBurnBalance
        autoBurnBalance += distribution + (amountWithDecimals % 4);
        maintenanceBalance += distribution;
    }

    // Allows the owner to set the liquidity threshold as a percentage of the total supply
    // where 0.01 would be entered as 1000
    function setLiquidityThreshold(uint256 percentage) private onlyOwner {
        require(percentage <= 10000, "Percentage should be less than or equal to 10000"); // Ensure the percentage is valid (up to 2 decimal places)
    
        uint256 totalSupply = totalSupply();
        liquidityThreshold = (totalSupply * percentage) / 10000; // Calculate the liquidity threshold based on the percentage
    }

    // Allows the owner to set the liquidity threshold directly in number of tokens
    function setLiquidityThresholdInTokens(uint256 newThresholdInTokens) private onlyOwner {
        liquidityThreshold = newThresholdInTokens * 10**18;
    }

    // Returns the current liquidity threshold without decimal places
    function getLiqThreshold() public view returns (uint256) {
        return liquidityThreshold / 10**18;
    }

    function manualConvert() external onlyOwner {
        _swapTokensForETH(devFeeBalance, _devWallet);
        devFeeBalance = 0;

        uint256 ethAmount = _swapTokensForETH(partnershipsBalance, address(this));
        partnershipsBalance = 0;
        _swapETHForPartnershipTokens(ethAmount);
        uint256 partnershipTokens = IERC20(_partnershipTokenAddress).balanceOf(address(this));
        IERC20(_partnershipTokenAddress).transfer(deadWallet, partnershipTokens);

        _burn(autoBurnBalance); // updated to use the 'burn' function
        autoBurnBalance = 0;

        _swapTokensForETH(maintenanceBalance, address(this)); // Swap maintenanceBalance for ETH
        maintenanceBalance = 0;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    // Check if sender or recipient are in exchangeWhitelist or maxWalletExcluded, if not, apply max wallet limit
    require(amount <= maxWalletAmount || exchangeWhitelist[sender] || exchangeWhitelist[recipient] || maxWalletExcluded[sender] || maxWalletExcluded[recipient], "Transfer amount exceeds the maxWalletAmount.");

    if (!inSwap && sender != uniswapV2Pair && (tradingEnabled || sender == owner() || sender == address(this))) {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= liquidityThreshold) {
            swapNow();
        }
    }

    // Add the logic to exclude certain operations
    bool isExcluded = whitelist[sender] || whitelist[recipient];
    bool takeFee = !isExcluded;

    if (takeFee) {
        Tax memory appliedTax = sender == uniswapV2Pair ? buyTax : sellTax;
        uint256 fees = amount * (appliedTax.devFee + appliedTax.partnerships + appliedTax.autoBurn + appliedTax.maintenance) / 100;
        amount -= fees;
        _tokenTransfer(sender, recipient, amount);
        distributeFee(fees, appliedTax);
    } else {
        _tokenTransfer(sender, recipient, amount);
    }
}





    function distributeFee(uint256 fees, Tax memory appliedTax) private {
        uint256 devFee = fees * appliedTax.devFee / 100;
        uint256 partnershipsFee = fees * appliedTax.partnerships / 100;
        uint256 autoBurnFee = fees * appliedTax.autoBurn / 100;
        uint256 maintenanceFee = fees * appliedTax.maintenance / 100;

        devFeeBalance += devFee;
        partnershipsBalance += partnershipsFee;
        autoBurnBalance += autoBurnFee;
        maintenanceBalance += maintenanceFee;
    }


    function swapNow() private lockTheSwap {
        uint256 devFee = devFeeBalance;
        uint256 partnershipsFee = partnershipsBalance;
        uint256 autoBurnFee = autoBurnBalance;
        uint256 maintenanceFee = maintenanceBalance;

        if (devFee > 0) {
            _swapTokensForETH(devFee, _devWallet);
            devFeeBalance = 0;
        }

        if (partnershipsFee > 0) {
            uint256 ethAmount = _swapTokensForETH(partnershipsFee, address(this));
            partnershipsBalance = 0;
            _swapETHForPartnershipTokens(ethAmount);
            uint256 partnershipTokens = IERC20(_partnershipTokenAddress).balanceOf(address(this));
            IERC20(_partnershipTokenAddress).transfer(deadWallet, partnershipTokens);
        }

        if (autoBurnFee > 0) {
            _burn(autoBurnFee);
            autoBurnBalance = 0;
        }

        if (maintenanceFee > 0) {
            _swapTokensForETH(maintenanceFee, address(this));
            maintenanceBalance = 0;
        }
    }



}