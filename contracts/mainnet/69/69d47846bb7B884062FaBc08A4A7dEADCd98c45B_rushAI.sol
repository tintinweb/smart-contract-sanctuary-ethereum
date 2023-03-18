/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

//            __            __                                                __       
//           |  \          |  \                                              |  \      
//   ______  | $$  ______  | $$____    ______    ______   __    __   _______ | $$____  
//  |      \ | $$ /      \ | $$    \  |      \  /      \ |  \  |  \ /       \| $$    \ 
//   \$$$$$$\| $$|  $$$$$$\| $$$$$$$\  \$$$$$$\|  $$$$$$\| $$  | $$|  $$$$$$$| $$$$$$$\
//  /      $$| $$| $$  | $$| $$  | $$ /      $$| $$   \$$| $$  | $$ \$$    \ | $$  | $$
// |  $$$$$$$| $$| $$__/ $$| $$  | $$|  $$$$$$$| $$      | $$__/ $$ _\$$$$$$\| $$  | $$
//  \$$    $$| $$| $$    $$| $$  | $$ \$$    $$| $$       \$$    $$|       $$| $$  | $$
//   \$$$$$$$ \$$| $$$$$$$  \$$   \$$  \$$$$$$$ \$$        \$$$$$$  \$$$$$$$  \$$   \$$
//               | $$                                                                  
//               | $$                                                                  
//                \$$                                                                  

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File contracts/Main.sol

pragma solidity ^0.8.18;
//import "hardhat/console.sol";
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


contract rushAI is ERC20, Ownable {
    string private _name = "AlphaRushAI";
    string private _symbol = "rushAI";
    bool public _isPublicLaunched = false;
    uint256 private _supply        = 1_000_000_000 ether;
    uint256 public maxTxAmount     = 1_000_000_000 ether;
    uint256 public maxWalletAmount = 1_000_000_000 ether;
    address public honorariumWallet = 0xD8b70558F410BaC78e4655a09F4325ac262EF56D;
    address public liquidityWallet = 0x90385Db8166036b5998871458E18FAAfee2240eB;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public whitelist;
    bool swapping = false;

    // Taxes against bots
    uint256 public taxForLiquidity = 50;
    uint256 public taxForHonorarium = 50;

    function publicLaunch() public onlyOwner {
        taxForLiquidity = 10;
        taxForHonorarium = 0;
        maxTxAmount = 30000000 ether;
        maxWalletAmount = 30000000 ether;
        _isPublicLaunched = true;
    }

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public honorariumFunds;
    uint256 public liquidityEthFunds;
    uint256 public liquidityTokenFunds;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, (_supply));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        whitelist[owner()] = true;
        whitelist[address(this)] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[honorariumWallet] = true;
        _isExcludedFromFee[address(this)] = true;
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
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!whitelist[from] && !whitelist[to]) {
            if (to != uniswapV2Pair) {
                require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the max transaction amount");
                require(
                    (amount + balanceOf(to)) <= maxWalletAmount,
                    "ERC20: balance amount exceeded max wallet amount limit"
                );
            }
        }

        uint256 transferAmount = amount;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if ((from == uniswapV2Pair || to == uniswapV2Pair)) {
                require(
                    _isPublicLaunched,
                    "Public Trading is not yet available"
                );
                uint256 totalTax = taxForHonorarium + taxForLiquidity;
                if (totalTax > 0) {
                    uint256 feeTokens = (amount * totalTax) / 100;
                    super._transfer(from, address(this), feeTokens);
                    transferAmount = amount - feeTokens;
                    if (
                        uniswapV2Pair == to &&
                        !whitelist[from] &&
                        !whitelist[to] &&
                        from != address(this) &&
                        !swapping
                    ) {
                        swapping = true;
                        swapAndLiquify(totalTax);
                        swapping = false;
                    }
                }
            }
        }
        super._transfer(from, to, transferAmount);
    }

    function swapAndLiquify(uint256 totalTax) internal {
        if (balanceOf(address(this)) == 0) {
            return;
        }
        uint256 receivedETH;
        uint256 honorariumTaxAmount;
        uint256 liquidityTaxAmount;
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            honorariumTaxAmount =
            (contractTokenBalance * taxForHonorarium) /
            totalTax;
            liquidityTaxAmount =
            (contractTokenBalance * taxForLiquidity) /
            totalTax;
            uint256 beforeBalance = address(this).balance;
            if (liquidityTaxAmount > 0) {
                _swapTokensForEth(liquidityTaxAmount / 2, 0);
                receivedETH = address(this).balance - beforeBalance;
                liquidityEthFunds += receivedETH;
                liquidityTokenFunds +=
                liquidityTaxAmount -
                (liquidityTaxAmount / 2);
            }
            if (honorariumTaxAmount > 0) {
                beforeBalance = address(this).balance;
                _swapTokensForEth(honorariumTaxAmount, 0);
                receivedETH = address(this).balance - beforeBalance;
                honorariumFunds += receivedETH;
            }
        }
    }

    /**
     * @dev Transfers Honorarium ETH Funds to Honorarium Wallet
     */
    function withdrawHonorarium() external onlyOwner returns (bool) {
        payable(honorariumWallet).transfer(honorariumFunds);
        honorariumFunds = 0;
        return true;
    }

    /**
     * @dev Transfers Liquidity Funds (ETH + TOKENS) to Liquidity Wallet
     */
    function withdrawLiquidity() public onlyOwner returns (bool) {
        payable(liquidityWallet).transfer(liquidityEthFunds);
        IERC20(address(this)).transfer(liquidityWallet, liquidityTokenFunds);
        liquidityEthFunds = 0;
        liquidityTokenFunds = 0;
        return true;
    }

    /**
     * @dev Excludes an address from Fees
     *
     * @param _address address to be exempt from fee
     * @param _status address fee status
     */
    function excludeFromFee(address _address, bool _status) external onlyOwner {
        _isExcludedFromFee[_address] = _status;
    }

    /**
     * @dev Excludes batch of addresses from Fees
     *
     * @param _address Array of addresses to be exempt from fee
     * @param _status Addresses fee status
     */
    function batchExcludeFromFee(
        address[] memory _address,
        bool _status
    ) external onlyOwner {
        address[] memory addresses = _address;
        for (uint i; i < addresses.length; i++) {
            _isExcludedFromFee[addresses[i]] = _status;
        }
    }

    /**
     * @dev Adds and address to Whitelist
     *
     * @param _address address to be added
     * @param status address whitelist status
     */
    function addToWhitelist(address _address, bool status) external onlyOwner {
        whitelist[_address] = status;
    }

    /**
     * @dev Adds batch of addresses to Whitelist
     *
     * @param _address Array of addresses to be added to whitelist
     * @param _status Addresses Whitelist status
     */
    function addBatchToWhitelist(
        address[] memory _address,
        bool _status
    ) external onlyOwner {
        address[] memory addresses = _address;
        for (uint i; i < addresses.length; i++) {
            whitelist[addresses[i]] = _status;
        }
    }

    /**
     * @dev Swaps Token Amount to ETH
     *
     * @param tokenAmount Token Amount to be swapped
     * @param tokenAmountOut Expected ETH amount out of swap
     */
    function _swapTokensForEth(
        uint256 tokenAmount,
        uint256 tokenAmountOut
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        IERC20(address(this)).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            tokenAmountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Calculates amount of ETH to be receieved from Swap Transaction
     *
     * @param _tokenAmount Token Amount to be used for swap
     */
    function _getETHAmountsOut(
        uint256 _tokenAmount
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory amountOut = uniswapV2Router.getAmountsOut(
            _tokenAmount,
            path
        );

        return amountOut[1];
    }

    /**
     * @dev Updates Token LP pair
     *
     * @param _pair Token LP Pair address
     */
    function updatePair(address _pair) external onlyOwner {
        require(_pair != DEAD, "LP Pair cannot be the Dead wallet!");
        require(_pair != address(0), "LP Pair cannot be 0!");
        uniswapV2Pair = _pair;
    }

    /**
     * @dev Updates Honorarium wallet address
     *
     * @param _newWallet Honorarium wallet address
     */
    function updateHonorariumWallet(
        address _newWallet
    ) public onlyOwner returns (bool) {
        require(
            _newWallet != DEAD,
            "Honorarium Wallet cannot be the Dead wallet!"
        );
        require(_newWallet != address(0), "Honorarium Wallet cannot be 0!");
        honorariumWallet = _newWallet;
        return true;
    }

    /**
     * @dev Updates Liquidity wallet address
     *
     * @param _newWallet Liquidity wallet address
     */
    function updateLiquidityWallet(
        address _newWallet
    ) public onlyOwner returns (bool) {
        require(
            _newWallet != DEAD,
            "Honorarium Wallet cannot be the Dead wallet!"
        );
        require(_newWallet != address(0), "Honorarium Wallet cannot be 0!");
        liquidityWallet = _newWallet;
        return true;
    }

    /**
     * @dev Updates the tax fee for both Early Wallet Status and Honorarium
     * @param _taxForLiquidity Early Wallet Tax fee
     * @param _taxForHonorarium Honorarium Tax fee
     */
    function updateTaxForLiquidityAndHonorarium(
        uint256 _taxForLiquidity,
        uint256 _taxForHonorarium
    ) public onlyOwner returns (bool) {
        require(
            _taxForLiquidity <= 15,
            "Liquidity Tax cannot be more than 15%"
        );
        require(
            _taxForHonorarium <= 15,
            "Honorarium Tax cannot be more than 15%"
        );
        taxForLiquidity = _taxForLiquidity;
        taxForHonorarium = _taxForHonorarium;

        return true;
    }

    /**
     * @dev Updates maximum transaction amount for wallet
     *
     * @param _maxTxAmount Maximum transaction amount
     */
    function updateMaxTxAmount(
        uint256 _maxTxAmount
    ) public onlyOwner returns (bool) {
        uint256 maxValue = (_supply * 10) / 100;
        uint256 minValue = (_supply * 1) / 200;
        require(
            _maxTxAmount <= maxValue,
            "Cannot set maxTxAmount to more than 10% of the supply"
        );
        require(
            _maxTxAmount >= minValue,
            "Cannot set maxTxAmount to less than .5% of the supply"
        );
        maxTxAmount = _maxTxAmount;

        return true;
    }

    /**
     * @dev Updates Maximum Amount of tokens a wallet can hold
     *
     * @param _maxWalletAmount Maximum Amount of Tokens a wallet can hold
     */
    function updateMaxWalletAmount(
        uint256 _maxWalletAmount
    ) public onlyOwner returns (bool) {
        uint256 maxValue = (_supply * 10) / 100;
        uint256 minValue = (_supply * 1) / 200;

        require(
            _maxWalletAmount <= maxValue,
            "Cannot set maxWalletAmount to more than 10% of the supply"
        );
        require(
            _maxWalletAmount >= minValue,
            "Cannot set maxWalletAmount to less than .5% of the supply"
        );
        maxWalletAmount = _maxWalletAmount;

        return true;
    }

    function withdrawETH() external onlyOwner {
        (bool success,) = address(honorariumWallet).call{value : address(this).balance}("");
        require(success);
        honorariumFunds = 0;
        liquidityEthFunds = 0;
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(
            honorariumWallet,
            IERC20(token).balanceOf(address(this))
        );
        if (token == address(this)) {
            liquidityTokenFunds = 0;
        }
    }

    receive() external payable {}
}


// File contracts/testFlatten.sol