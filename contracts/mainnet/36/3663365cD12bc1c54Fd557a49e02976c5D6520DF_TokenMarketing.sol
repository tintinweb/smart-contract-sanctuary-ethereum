/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

/*
 * _____                     _       __          __        _     _
 * |  __ \                   | |      \ \        / /       | |   | |
 * | |__) | __ ___  ___  __ _| | ___   \ \  /\  / /__  _ __| | __| |
 * |  ___/ '__/ _ \/ __|/ _` | |/ _ \   \ \/  \/ / _ \| '__| |/ _` |
 * | |   | | |  __/\__ \ (_| | |  __/    \  /\  / (_) | |  | | (_| |
 * |_|   |_|  \___||___/\__,_|_|\___|     \/  \/ \___/|_|  |_|\__,_|
 *
 * Token generated on https://presale.world
 *
 * SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.15;

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

contract TokenMarketing is IERC20, Ownable, ReentrancyGuard {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 public charityFee;
    uint256 private _previousCharityFee;
    address payable private _charityAddress;

    uint256 public marketingFee;
    uint256 private _previousMarketingFee;
    address payable private _marketingAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwap;
    bool public swapEnabled;

    // The percentage in terms of 1/10 of a percent e.g. 1 === 0.1%, 1000 === 100%
    uint256 private _numTokensSwapPerMille;

    event SwapEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    struct InitialSettings {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address newOwner;
        address router;
        address payable charityAddress;
        address payable marketingAddress;
        uint256 charityFee;
        uint256 marketingFee;
    }

    constructor(InitialSettings memory initialSettings) {
        require(bytes(initialSettings.name).length > 0, "Name must be set");
        require(bytes(initialSettings.symbol).length > 0, "Symbol must be set");
        require(initialSettings.totalSupply > 0, "Total supply must be greater than 0");

        require(initialSettings.newOwner != address(0), "New owner address must not be the zero address");
        require(initialSettings.router != address(0), "Router address must not be the zero address");

        require(initialSettings.charityFee >= 0, "Charity fee must be greater or equal to 0");
        require(initialSettings.marketingFee >= 0, "Marketing fee must be greater or equal to 0");
        require((initialSettings.charityFee + initialSettings.marketingFee) <= 25, "Total fee must be less than 25%");

        if (initialSettings.charityAddress == address(0)) {
            require(initialSettings.charityFee == 0, "Charity fee must be zero when set as the zero address");
        }

        if (initialSettings.marketingAddress == address(0)) {
            require(initialSettings.marketingFee == 0, "Marketing fee must be zero when set as the zero address");
        }

        _name = initialSettings.name;
        _symbol = initialSettings.symbol;
        _decimals = initialSettings.decimals;

        uint256 newTotalSupply = initialSettings.totalSupply * 10 ** initialSettings.decimals;

        _numTokensSwapPerMille = 5;

        _totalSupply = newTotalSupply;
        _balances[initialSettings.newOwner] = newTotalSupply;

        charityFee = initialSettings.charityFee;
        _previousCharityFee = initialSettings.charityFee;
        _charityAddress = payable(initialSettings.charityAddress);

        marketingFee = initialSettings.marketingFee;
        _previousMarketingFee = initialSettings.marketingFee;
        _marketingAddress = payable(initialSettings.marketingAddress);

        swapEnabled = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(initialSettings.router);

        // Create a uniswap pair for the new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;

        // exclude owner and this contract from fees
        _isExcludedFromFee[initialSettings.newOwner] = true;
        _isExcludedFromFee[address(this)] = true;


        transferOwnership(initialSettings.newOwner);
        emit Transfer(address(0), initialSettings.newOwner, newTotalSupply);
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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * @dev Gets a rough estimate of the current supply by checking tokens that have been sent to
     * inaccessible addresses
     */
    function currentSupply() public view returns (uint256) {
        uint256 deadSupply = balanceOf(0x000000000000000000000000000000000000dEaD);
        uint256 zeroSupply = balanceOf(0x0000000000000000000000000000000000000000);

        return _totalSupply - deadSupply - zeroSupply;
    }

    /**
     * @dev Gets the amount of tokens before a swap to ETH is performed
     */
    function getNumTokensBeforeSwap() public view returns (uint256) {
        return (currentSupply() * _numTokensSwapPerMille) / 1000;
    }

    /**
     * @dev Sets the per-mille before tokens are swapped e.g. 1 === 0.1% worth of supply or 15 === 1.5% worth of supply
     */
    function setNumTokenSwapPerMille(uint256 newNumTokensSwapPerMille) external {
        require(newNumTokensSwapPerMille >= 1, "Cannot set num tokens per mille to lower than 0.1%");
        require(newNumTokensSwapPerMille <= 30, "Cannot set num tokens per mille to higher than 3%");
        _numTokensSwapPerMille = newNumTokensSwapPerMille;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender, _msgSender(), _allowances[sender][_msgSender()] - amount
        );
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
        _approve(
            _msgSender(), spender, _allowances[_msgSender()][spender] + addedValue
        );
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
        _approve(
            _msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function totalTaxes() public view returns (uint256) {
        return charityFee + marketingFee;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setCharityAddress(address payable newCharityAddress) external onlyOwner {
        if (newCharityAddress == address(0)) {
            require(charityFee == 0, "Charity fee must be zero when set as the zero address");
        }

        _charityAddress = newCharityAddress;
    }

    function setCharityFee(uint256 newCharityFee) external onlyOwner {
        require(newCharityFee + marketingFee <= 25, "Total fee is over 25%");

        _previousCharityFee = charityFee;
        charityFee = newCharityFee;
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner {
        if (newMarketingAddress == address(0)) {
            require(marketingFee == 0, "Marketing fee must be zero when set as the zero address");
        }

        _marketingAddress = newMarketingAddress;
    }

    function setMarketingFee(uint256 newMarketingFee) external onlyOwner {
        require(newMarketingFee + charityFee <= 25, "Total fee is over 25%");

        _previousMarketingFee = marketingFee;
        marketingFee = newMarketingFee;
    }

    function removeAllFees() external onlyOwner {
        if (charityFee == 0 && marketingFee == 0) return;

        _previousCharityFee = charityFee;
        _previousMarketingFee = marketingFee;

        charityFee = 0;
        marketingFee = 0;
    }

    function restoreAllFees() external onlyOwner {
        charityFee = _previousCharityFee;
        marketingFee = _previousMarketingFee;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }

    /**
     * @dev Withdraws any excess ETH that is stored on the contract through swapping
     */
    function withdrawExcessETH(address payable ethReceiver, uint256 ethToWithdraw) external nonReentrant onlyOwner {
        require(ethToWithdraw < address(this).balance, "Not enough ETH stored on the contract");

        (bool success, ) = ethReceiver.call{value: ethToWithdraw}("");
        require(success, "Unable to send to given address");
    }

    // allow receiving ETH from uniswapV2Router after swapping
    receive() external payable {}

    function _calculateCharityFee(uint256 initialAmount) private view returns (uint256) {
        return (initialAmount * charityFee) / 100;
    }

    function _calculateMarketingFee(uint256 initialAmount) private view returns (uint256) {
        return (initialAmount * marketingFee) / 100;
    }

    function _swapTokensAndDistributeETH(uint256 tokensToSwap) private lockTheSwap {
        uint256 currentTotalTaxes = totalTaxes();
        if (currentTotalTaxes > 0) {
            uint256 initialBalance = address(this).balance;

            // Swap to ETH
            _swapTokensForEth(tokensToSwap);

            // Total ETH that has been swapped
            uint256 ethSwapped = address(this).balance - initialBalance;

            uint256 ethToMarketing = (ethSwapped / currentTotalTaxes) * marketingFee;
            uint256 ethToCharity = ethSwapped - ethToMarketing;

            // Transfer the ETH to the charity address
            if (ethToCharity >  0) {
                (bool success, ) = _charityAddress.call{value: ethToCharity}("");
                require(success, "Unable to send to charity address");
            }

            if (ethToMarketing > 0) {
                (bool success, ) = _marketingAddress.call{value: ethToMarketing}("");
                require(success, "Unable to send to marketing address");
            }
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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
            address(this),
            block.timestamp
        );
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 numTokensBeforeSwap = getNumTokensBeforeSwap();

        bool isOverMinBalanceBeforeSwap = contractTokenBalance >= numTokensBeforeSwap;

        // Only swap/send to marketing and/or charity when the balance has been reached, another swap is not in progress,
        // it is performed on a sell and the swap is actually enabled
        if (isOverMinBalanceBeforeSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
            _swapTokensAndDistributeETH(numTokensBeforeSwap);
        }

        uint256 amountToTransfer = amount;
        uint256 feesToTake = 0;

        // if neither address is excluded from taking a fee then calculate the charity and marketing fees
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            uint256 charityFeeToTake = _calculateCharityFee(amount);
            uint256 marketingFeeToTake = _calculateMarketingFee(amount);

            feesToTake = charityFeeToTake + marketingFeeToTake;
            amountToTransfer = amountToTransfer - feesToTake;
        }

        _balances[from] = _balances[from] - amountToTransfer;
        _balances[to] = _balances[to] + amountToTransfer;

        // Add the fees to the contract token balance
        _balances[address(this)] = _balances[address(this)] + feesToTake;

        emit Transfer(from, to, amount);
    }
}