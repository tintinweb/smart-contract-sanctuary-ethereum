/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

pragma solidity ^0.8.0;

/**
 * 
 * Shiba Gift
 * The First Real Children Charity Shibarium Project
 *
 * Telegram: https://t.me/ShibaGiftOfficial
 * Website: https://shibagift.net/
 *
 * 
 *
 *
 *
 *
 *
 *
 *
 *
 * This contract is developed and licensed by CryptoolsAI project and it is in beta testing. 
 * Any re-use of this contract without CryptoolsAI authorization is truly forbidden and restricted.
 * No-Responsibility Disclaimer: CryptoolsAI DOES NOT accept any liability for any loss caused by others from using its products (this contract). CryptoolsAI just provides this contract to project owner who is launching this token and is not responsible for anything else.
 * Telegram: https://t.me/CryptoolsAI
 *
 **/

 // SPDX-License-Identifier: None
 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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




pragma solidity ^0.8.4;

interface IDexFactory {
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

interface IDexPair {
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

		event Mint(address indexed sender, uint amount0, uint amount1);
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

		function mint(address to) external returns (uint liquidity);
		function burn(address to) external returns (uint amount0, uint amount1);
		function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
		function skim(address to) external;
		function sync() external;

		function initialize(address, address) external;
}

interface IDexRouter{
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

contract ShibaGiftToken is ERC20, Ownable {
    // tax
    uint256 FeeDecimals = 1000000;
    struct Fee {
        uint256 marketing_fee;
        uint256 team_fee;
        uint256 reserve_fee;
        uint256 reward_fee;
        uint256 auto_lp;
        uint256 launchai_fee;
    }
    struct FeeWallet {
        address marketing;
        address team;
        address reserve;
    }

    uint8 _decimals = 18;
    uint256 private launchai_fee_default = 15; // 15%

    Fee private sellFees;
    Fee private buyFees;
    FeeWallet public feeWallets;

    uint256 marketingPercent;
    uint256 teamPercent;
    uint256 reservePercent;
    uint256 autoLPPercent;
    uint256 rewardPercent;
    uint256 LaunchAIPercent;

    mapping(address => bool) public isExcludeFromFee;

    // tx limit
    uint256 public _maxTxAmount;
    uint256 public _maxAmountPerWallet;
    uint256 public _numTokensSellToAddToLiquidity;
    bool public _swapAndLiquifyEnabled = true;

    // exchange info
    IDexRouter public DexRouter;
    address public DexPair;

    //swap
    bool public inSwapAndLiquify;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // tool fee
    address CashierWallet = 0xd36aAdb5453C02528E40D3Aa612F65dd42802263 ;
    address ToolTokenAddress = 0x64A7C4bB46713882fcE0dAe61547568eb358c5EA;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimals_,
        address _RouterAddress,
        uint256 maxTxAmount_,
        uint256 maxAmountPerWallet_,
        uint256 numTokensSellToAddToLiquidity_
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _decimals = decimals_;

        IDexRouter _DexRouter = IDexRouter(_RouterAddress);
        DexRouter = _DexRouter;
        DexPair = IDexFactory(_DexRouter.factory()).createPair(
            address(this),
            _DexRouter.WETH()
        );

        isExcludedFromReward[DexPair] = true;
        isExcludedFromReward[address(this)] = true;
        isExcludeFromFee[msg.sender] = true;

    
        // init fees
        _maxTxAmount = maxTxAmount_;
        _maxAmountPerWallet = maxAmountPerWallet_;
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity_;

        feeWallets.marketing = 0x65103AB264950Ea055E301F6079a9171b3dc18e5;
        feeWallets.team = 0x65103AB264950Ea055E301F6079a9171b3dc18e5;
        feeWallets.reserve = 0xA5AA30C15fe4C2c0bd16Dfd5Fa43eAa550079228;
    }

    function setFees(
        uint256 sell_marketing_fee, // 1000 : 0.1%
        uint256 sell_team_fee,
        uint256 sell_reserve_fee,
        uint256 sell_reward_fee,
        uint256 sell_auto_lp,
        uint256 buy_marketing_fee,
        uint256 buy_team_fee,
        uint256 buy_reserve_fee,
        uint256 buy_reward_fee,
        uint256 buy_auto_lp
    ) external onlyOwner {
        sellFees.marketing_fee =
            (sell_marketing_fee * (100 - launchai_fee_default)) /
            100;
        sellFees.team_fee =
            (sell_team_fee * (100 - launchai_fee_default)) /
            100;
        sellFees.reserve_fee =
            (sell_reserve_fee * (100 - launchai_fee_default)) /
            100;
        sellFees.reward_fee =
            (sell_reward_fee * (100 - launchai_fee_default)) /
            100;
        sellFees.auto_lp = (sell_auto_lp * (100 - launchai_fee_default)) / 100;
        sellFees.launchai_fee =
            ((sell_marketing_fee +
                sell_team_fee +
                sell_reserve_fee +
                sell_reward_fee +
                sell_auto_lp) * launchai_fee_default) /
            100;

        buyFees.marketing_fee =
            (buy_marketing_fee * (100 - launchai_fee_default)) /
            100;
        buyFees.team_fee = (buy_team_fee * (100 - launchai_fee_default)) / 100;
        buyFees.reserve_fee =
            (buy_reserve_fee * (100 - launchai_fee_default)) /
            100;
        buyFees.reward_fee =
            (buy_reward_fee * (100 - launchai_fee_default)) /
            100;
        buyFees.auto_lp = (buy_auto_lp * (100 - launchai_fee_default)) / 100;
        buyFees.launchai_fee =
            ((buy_marketing_fee +
                buy_team_fee +
                buy_reserve_fee +
                buy_reward_fee +
                buy_auto_lp) * launchai_fee_default) /
            100;
        // if total fee is under 0.5%
        if (getTotalSellFee() <= 5000) {
            sellFees.launchai_fee = 1000;
        }
        if (getTotalBuyFee() <= 5000) {
            buyFees.launchai_fee = 1000;
        }

      // require(getTotalSellFee() <= 200000, "fee is over 20%");
      // require(getTotalBuyFee() <= 200000, "fee is over 20%");
    }

    //unction initialAddLiquidity(uint256 tokenAmount) external payable {
      //  uint256 ETHamount = msg.value;
      //  addLiquidity(tokenAmount, ETHamount);
    //}

    function setTxLimit(
        uint256 maxTxAmount,
        uint256 maxAmountPerWallet,
        uint256 numTokensSellToAddToLiquidity,
        bool swapAndLiquifyEnabled
    ) external onlyOwner {
        _maxTxAmount = maxTxAmount;
        _maxAmountPerWallet = maxAmountPerWallet;
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
        _swapAndLiquifyEnabled = swapAndLiquifyEnabled;

        require(
            (_maxTxAmount > (totalSupply() * 100) / 10000),
            "max tx amount can't be lower than 1%"
        );

        require(
            (_maxAmountPerWallet > (totalSupply() * 100) / 10000),
            "max wallet amount can't be lower than 1%"
        );
    }

    function getTotalSellFee() public view returns (uint256 totalFee) {
        totalFee =
            sellFees.marketing_fee +
            sellFees.team_fee +
            sellFees.reserve_fee +
            sellFees.reward_fee +
            sellFees.launchai_fee +
            sellFees.auto_lp;
    }

    function getTotalBuyFee() public view returns (uint256 totalFee) {
        totalFee =
            buyFees.marketing_fee +
            buyFees.team_fee +
            buyFees.reserve_fee +
            buyFees.reward_fee +
            buyFees.launchai_fee +
            buyFees.auto_lp;
    }

    function getBuyFees()
        public
        view
        returns (
            uint256 marketing_fee,
            uint256 team_fee,
            uint256 reserve_fee,
            uint256 reward_fee,
            uint256 auto_lp
        )
    {
        marketing_fee =
            (buyFees.marketing_fee * 100) /
            (100 - launchai_fee_default);
        team_fee = (buyFees.team_fee * 100) / (100 - launchai_fee_default);
        reserve_fee =
            (buyFees.reserve_fee * 100) /
            (100 - launchai_fee_default);
        reward_fee = (buyFees.reward_fee * 100) / (100 - launchai_fee_default);
        auto_lp = (buyFees.auto_lp * 100) / (100 - launchai_fee_default);
    }

    function getSellFees()
        public
        view
        returns (
            uint256 marketing_fee,
            uint256 team_fee,
            uint256 reserve_fee,
            uint256 reward_fee,
            uint256 auto_lp
        )
    {
        marketing_fee =
            (sellFees.marketing_fee * 100) /
            (100 - launchai_fee_default);
        team_fee = (sellFees.team_fee * 100) / (100 - launchai_fee_default);
        reserve_fee =
            (sellFees.reserve_fee * 100) /
            (100 - launchai_fee_default);
        reward_fee = (sellFees.reward_fee * 100) / (100 - launchai_fee_default);
        auto_lp = (sellFees.auto_lp * 100) / (100 - launchai_fee_default);
    }

    function setFeeWallets(
        address marketing,
        address team,
        address reserve
    ) external onlyOwner {
        feeWallets.marketing = marketing;
        feeWallets.team = team;
        feeWallets.reserve = reserve;
    }

    function setExcludFromFee(address to, bool _excluded) external onlyOwner {
        isExcludeFromFee[to] = _excluded;
    }

    function _transferWithOutFeeCalculate(
        address from,
        address to,
        uint256 amount
    ) internal {
        super._transfer(from, to, amount);
        tokenTransferReward(from, to, amount);
        transferForExcludeReward(from, to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // normal transfer for fee excluded wallet
        if (isExcludeFromFee[from] || isExcludeFromFee[to]) {
            _transferWithOutFeeCalculate(from, to, amount);
            return;
        }
        require(
            amount <= _maxTxAmount || from == owner() || to == owner(),
            "Exceed max transfer amount"
        );
        uint256 recieveAmount = amount;
        if (to == DexPair) {
            //sell
            _transferWithOutFeeCalculate(
                from,
                address(this),
                (amount * getTotalSellFee()) / FeeDecimals
            );
            marketingPercent += (amount * sellFees.marketing_fee) / FeeDecimals;
            teamPercent += (amount * sellFees.team_fee) / FeeDecimals;
            reservePercent += (amount * sellFees.reserve_fee) / FeeDecimals;
            autoLPPercent += (amount * sellFees.auto_lp) / FeeDecimals;
            rewardPercent += (amount * sellFees.reward_fee) / FeeDecimals;
            LaunchAIPercent += (amount * sellFees.launchai_fee) / FeeDecimals;

            recieveAmount = amount - (amount * getTotalSellFee()) / FeeDecimals;
        } else if (from == DexPair) {
            //buy
            _transferWithOutFeeCalculate(
                from,
                address(this),
                (amount * getTotalBuyFee()) / FeeDecimals
            );

            marketingPercent += (amount * buyFees.marketing_fee) / FeeDecimals;
            teamPercent += (amount * buyFees.team_fee) / FeeDecimals;
            reservePercent += (amount * buyFees.reserve_fee) / FeeDecimals;
            autoLPPercent += (amount * buyFees.auto_lp) / FeeDecimals;
            rewardPercent += (amount * buyFees.reward_fee) / FeeDecimals;
            LaunchAIPercent += (amount * buyFees.launchai_fee) / FeeDecimals;

            recieveAmount = amount - (amount * getTotalBuyFee()) / FeeDecimals;
        }
        {
            // normal transfer
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }
            bool overMinTokenBalance = contractTokenBalance >=
                _numTokensSellToAddToLiquidity;
            if (
                !inSwapAndLiquify && from != DexPair && _swapAndLiquifyEnabled
            ) {
                if (overMinTokenBalance)
                    contractTokenBalance = _numTokensSellToAddToLiquidity;
                //add liquidity
                swapAndLiquify(contractTokenBalance);
            }
        }
        if (!inSwapAndLiquify && address(this).balance > 1e15)
            process(distributorGas);

        require(
            balanceOf(to) + recieveAmount <= _maxAmountPerWallet ||
                from == owner() ||
                to == owner() ||
                to == DexPair,
            "Exceed max transfer amount"
        );
        _transferWithOutFeeCalculate(from, to, recieveAmount);
        setShareholder(from);
        setShareholder(to);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // total reward amount
        uint256 totalPercent = autoLPPercent +
            marketingPercent +
            teamPercent +
            reservePercent +
            LaunchAIPercent +
            rewardPercent;

        // split the contract balance into halves
        if (totalPercent == 0) return;

        if (contractTokenBalance > totalPercent)
            contractTokenBalance = totalPercent;

        // each fee amount base on percent
        uint256 autoLPAmount = (contractTokenBalance * autoLPPercent) /
            totalPercent;
        uint256 marketingFeeAmount = (contractTokenBalance * marketingPercent) /
            totalPercent;
        uint256 teamFeeAmount = (contractTokenBalance * teamPercent) /
            totalPercent;
        uint256 reserveFeeAmount = (contractTokenBalance * reservePercent) /
            totalPercent;
        uint256 LaunchAIFeeAmount = (contractTokenBalance * LaunchAIPercent) /
            totalPercent;

        uint256 rewardFeeAmount = (contractTokenBalance * rewardPercent) /
            totalPercent;

        // // fee share
        uint256 otherHalf = contractTokenBalance - autoLPAmount / 2;
        uint256 initialBalance = address(this).balance;

        if (otherHalf > 0) swapTokensForEth(otherHalf);
        if (autoLPAmount > 0)
            addLiquidity(
                autoLPAmount / 2,
                address(this).balance - initialBalance
            );

        // remained balance to reward launchAI, marketing, team and reserve
        uint256 remainedBalance = address(this).balance - initialBalance;

        // total percent
        totalPercent =
            marketingPercent +
            teamPercent +
            reservePercent +
            LaunchAIPercent +
            rewardPercent;

        // distribute fees
        uint256 LaunchAIFeeBalance = (remainedBalance * LaunchAIPercent) /
            totalPercent;
        uint256 marketingFeeBalance = (remainedBalance * marketingPercent) /
            totalPercent;
        uint256 teamFeeBalance = (remainedBalance * teamPercent) / totalPercent;
        uint256 reserveFeeBalance = (remainedBalance * reservePercent) /
            totalPercent;
        uint256 rewardFeeBalance = (remainedBalance * rewardPercent) /
            totalPercent;

        payable(feeWallets.marketing).transfer(marketingFeeBalance);
        payable(feeWallets.team).transfer(teamFeeBalance);
        payable(feeWallets.reserve).transfer(reserveFeeBalance);

        if (LaunchAIFeeBalance > 0) swapETHForToolToken(LaunchAIFeeBalance);

        addReward(rewardFeeBalance);

        autoLPPercent -= autoLPAmount;
        LaunchAIPercent -= LaunchAIFeeAmount;
        marketingPercent -= marketingFeeAmount;
        teamPercent -= teamFeeAmount;
        reservePercent -= reserveFeeAmount;
        rewardPercent -= rewardFeeAmount;
    }

    // auto lp
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DexRouter.WETH();

        _approve(address(this), address(DexRouter), tokenAmount);

        DexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(DexRouter), tokenAmount);

        DexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    // tool

    function swapETHForToolToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = DexRouter.WETH();
        path[1] = ToolTokenAddress;

        DexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: tokenAmount
        }(0, path, CashierWallet, block.timestamp);
    }

    // reward section
    mapping(address => uint256) public rewardedAmount; // already rewarded amount
    mapping(address => uint256) rewardableAmount; // rewardable amount

    uint256 rewardRate; // reward amount per token
    uint256 totalRewardableAmount; //total reward pool amount

    mapping(address => bool) public isExcludedFromReward;
    uint256 totalExcludedAmount;

    function setExcludedFromReward(address to, bool data) external onlyOwner {
        if (isExcludedFromReward[to] != data) {
            isExcludedFromReward[to] = data;
            if (data) {
                // set to exclude
                totalExcludedAmount += balanceOf(to);
            } else {
                // remove from exclude
                totalExcludedAmount -= balanceOf(to);
                uint256 newRewardBalance = getClaimableReward(to);
                rewardedAmount[msg.sender] += newRewardBalance;
            }
        }
    }

    function transferForExcludeReward(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (isExcludedFromReward[from]) totalExcludedAmount -= amount;
        if (isExcludedFromReward[to]) totalExcludedAmount += amount;
    }

    function addReward(uint256 amount) internal {
        if (totalSupply() - totalExcludedAmount == 0) return;
        rewardRate += (amount * 1e18) / (totalSupply() - totalExcludedAmount);
    }

    function getClaimableReward(address to) public view returns (uint256) {
        if (isExcludedFromReward[to] || to == address(0)) return 0;
        if (
            (balanceOf(to) * rewardRate) / 1e18 + rewardableAmount[to] <
            rewardedAmount[to]
        ) return 0;
        return
            (balanceOf(to) * rewardRate) /
            1e18 +
            rewardableAmount[to] -
            rewardedAmount[to];
    }

    function claimReward() external {
        uint256 rewardAmount = getClaimableReward(msg.sender);
        rewardedAmount[msg.sender] += rewardAmount;
        payable(msg.sender).transfer(rewardAmount);
    }

    function tokenTransferReward(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 rewardAmount = (amount * rewardRate) / 1e18;
        rewardableAmount[from] += rewardAmount;
        rewardedAmount[to] += rewardAmount;
    }

    receive() external payable {}

    function claimstuckedToken(
        address token,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) payable(msg.sender).transfer(amount);
        else IERC20(token).transfer(msg.sender, amount);
    }

    // auto reward
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    bool public distributionEnabled = true;
    uint256 minPeriod = 45 * 60;
    uint256 minDistribution = 2 * (10 ** 10);
    uint256 currentIndex;
    uint256 distributorGas = 500000;

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        bool _enabled
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        distributionEnabled = _enabled;
    }

    function setShareholder(address shareholder) internal {
        if (balanceOf(shareholder) > 0) {
            if (shareholderIndexes[shareholder] == 0) {
                if (shareholders.length == 0 || shareholders[0] != shareholder)
                    addShareholder(shareholder);
            }
        } else {
            if (shareholderIndexes[shareholder] != 0)
                removeShareholder(shareholder);
        }
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function process(uint256 gas) internal {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0 || !distributionEnabled) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            uint256 rewardAmount = getClaimableReward(
                shareholders[currentIndex]
            );
            if (rewardAmount > minDistribution) {
                rewardedAmount[shareholders[currentIndex]] += rewardAmount;
                payable(shareholders[currentIndex]).call{value: rewardAmount}(
                    ""
                );
            }
            gasUsed = gasUsed + gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
}