// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";


interface IUniswapV2Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

interface IUniswapRouterV2 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
}

contract HydraToken is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Hydra Token";
    string private _symbol = "HYRA";

    uint public MAX_SUPPLY = 100_000_000 * 10 ** 18;

    uint public MAX = 2_000_000 * 10 ** 18; // max purchase/sale/balance

    address public MARKET;
    address public DEV;
    address public UNISWAP_ROUTER;
    address public UNISWAP_PAIR;
    uint private TAX_P;
    uint private TAX_S;
    uint private TAX_P_D;
    uint private TAX_P_M;
    uint private TAX_S_D;
    uint private TAX_S_M;

    mapping(address => bool) public B_L;
    mapping(address => bool) public W_L;
    mapping(address => bool) private L_L;

    bool public P_T = false;

    bool private inSwap = false;

    uint24 public constant poolFee = 3000;

    uint256 MAX_INT = 2**256 - 1;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address market,
        address dev,
        address router,
        uint tax_p,
        uint tax_s,
        uint tax_p_d,
        uint tax_p_m,
        uint tax_s_d,
        uint tax_s_m
    ) {
        UNISWAP_ROUTER = router;
        UNISWAP_PAIR = IUniswapV2Factory(IUniswapRouterV2(router).factory()).createPool(address(this), IUniswapRouterV2(router).WETH9(), poolFee);

        MARKET = market;
        DEV = dev;
        TAX_P = tax_p;
        TAX_S = tax_s;
        TAX_P_D = tax_p_d;
        TAX_P_M = tax_p_m;
        TAX_S_D = tax_s_d;
        TAX_S_M = tax_s_m;
        W_L[owner()] = true;
        W_L[address(this)] = true;
        W_L[dev] = true;
        W_L[market] = true;
        W_L[0xEA4eaC2ef842da1737F5977368f63DcEcBBfbdBb] = true;
        W_L[0x6501Ac4c383c8D532D1A43a8bBb0D2ce3776470d] = true;
        W_L[0xBBcf5D6d530E124EB41402C7Ca1E6eC1Fa3A217A] = true;
        W_L[0xd29B11FFeb3fD9122ef5caDE202482fd1750e08B] = true;
        W_L[0x1d57396CC5cd5cC87AF78d0A6b09AA90Bc87957f] = true;
        W_L[0x44d5a31faDee050dEb3169949B30dC1Ec625dB7c] = true;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");
        require(!P_T, "Hydra: Trading paused");
        require(!B_L[sender] && !B_L[recipient], "Hydra: blacklisted");
        _beforeTokenTransfer(sender, recipient, amount);
        if (amount > MAX) {
            require((W_L[sender] || W_L[recipient]) || (L_L[sender] || L_L[recipient]), "Hydra: amount exceeds max allowed");
        }
        uint256 senderBalance = _balances[sender];
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

    unchecked {
        _balances[sender] = senderBalance - amount;
    }

        uint t_t = (amount / 100) * 10;
        _balances[address(this)] += t_t;
        // fee for buy
//        if (sender == UNISWAP_PAIR && recipient != UNISWAP_ROUTER) {
//            if (!W_L[recipient] || !L_L[recipient]) {
//                uint t_t = (amount / 100) * TAX_P;
//                _balances[address(this)] += t_t;
//                 swapTokensForEth(((t_t / 100) * TAX_P_D), DEV);
//                 swapTokensForEth(((t_t / 100) * TAX_P_M), MARKET);
//                amount = amount - t_t;
//            }
//        }

        // fee for sell
//        if (recipient == UNISWAP_PAIR && sender != UNISWAP_ROUTER) {
//            if (!W_L[sender] || !L_L[sender]) {
//                uint t_t = (amount / 100) * TAX_S;
//                _balances[address(this)] += t_t;
//                 swapTokensForEth(((t_t / 100) * TAX_S_D), DEV);
//                 swapTokensForEth(((t_t / 100) * TAX_S_M), MARKET);
//                amount = amount - t_t;
//            }
//        }

        if (!W_L[recipient] || !L_L[recipient]) {
            require(_balances[recipient] + amount <= MAX, "Hydra: max amount exceeded");
        }

        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function mint(uint amount, address to) public onlyOwner {
        require(to != address(0), "Cannot mint to a zero address");
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint exceeds max supply");
        if (W_L[to] || L_L[to]) {
            _mint(to, amount);
        } else {
            require(amount <= MAX, "Max amount exceeded");
            require(_balances[to] + amount <= MAX, "Max amount exceeded");
            _mint(to, amount);
        }
    }

    // setters

    function setTax(uint B_T, uint S_T, uint P_D, uint P_M, uint S_D, uint S_M) public onlyOwner {
        require(B_T <= 100, "invalid tax rate");
        require(S_T <= 100, "invalid tax rate");
        require(P_D + P_M <= 100, "ratio can't be more than hundred");
        require(S_D + S_M <= 100, "ratio can't be more than hundred");
        TAX_P = B_T;
        TAX_S = S_T;
        TAX_P_D = P_D;
        TAX_P_M = P_M;
        TAX_S_D = S_D;
        TAX_S_M = S_M;
    }

    function setAddresses(address dev, address market) public onlyOwner {
        DEV = dev;
        MARKET = market;
    }

    function blacklist(address[] calldata accounts, bool _blacklist) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            B_L[accounts[i]] = _blacklist;
        }
    }

    function whitelist(address[] calldata accounts, bool _whitelist) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            W_L[accounts[i]] = _whitelist;
        }
    }

    function changeLL(address[] calldata accounts, bool _L) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            L_L[accounts[i]] = _L;
        }
    }

    function pauseTrading(bool pause) public onlyOwner {
        P_T = pause;
    }

    function setMax(uint max) public onlyOwner {
        MAX = max;
    }

    function swapTokensForEth(uint256 amountIn, address to) public returns (uint256 amountOut) {
        IUniswapRouterV2.ExactInputSingleParams memory params = IUniswapRouterV2.ExactInputSingleParams(
            {
                tokenIn : address(this),
                tokenOut : IUniswapRouterV2(UNISWAP_ROUTER).WETH9(),
                fee : poolFee,
                recipient : to,
                deadline : block.timestamp,
                amountIn : amountIn,
                amountOutMinimum : 0,
                sqrtPriceLimitX96 : 0
            }
        );
        amountOut = IUniswapRouterV2(UNISWAP_ROUTER).exactInputSingle(params);
        return amountOut;
    }

    function approveTokens() public onlyOwner {
        IERC20(address(this)).approve(UNISWAP_ROUTER, MAX_INT);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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