// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './Common.sol';
import './Param.sol';

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


contract MPEToken is Context, IERC20, Ownable, Param {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string public name = "MPE Token";
    string public symbol = "MPE";
    uint256 public decimals = 18;

    uint256 private _totalSupply;
    uint256 public burnTotalSupply;
    uint256 public minTotalSupply = 20000000 * 10 ** decimals;

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
    address public uniswapV2PairIMAU;
    address public uniswapV2PairUSDT;
    address public uniswapV2PairBNB;

    uint8 private daoFundRate = 10;
    uint8 private burnRate = 10;
    mapping(address => bool) private excluded;
    mapping(address => bool) private limits;

    uint256 private startTime = 1679452352;

    bool public feeState = true;

    constructor() {
        _mint(owner(), 100000000 * 10 ** decimals);

        uniswapV2PairBNB = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2PairUSDT = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), usdt);
        uniswapV2PairIMAU = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), imau);

        excluded[owner()] = true;
        excluded[address(this)] = true;
        excluded[address(uniswapV2Router)] = true;
        excluded[daoFund] = true;
    }

    receive() external payable {}

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function start() public onlyOwner {
        startTime = block.timestamp;
    }

    function setExcluded(address _addr, bool _state) public onlyOwner {
        excluded[_addr] = _state;
    }

    function setFeeState(bool _feeState) public onlyOwner {
        feeState = _feeState;
    }

    function setLimit(address addr, bool state) public onlyOwner {
        limits[addr] = state;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(uint256 amount) public {
        address spender = _msgSender();
        _burn(spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "MPEToken: transfer from the zero address");
        require(to != address(0), "MPEToken: transfer to the zero address");
        require(!limits[from], "MPEToken: limit address");

        _tradeControl(from, to);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "MPEToken: transfer amount exceeds balance");

        _balances[from] = fromBalance - amount;

        uint256 finalAmount = feeState ? _fee(from, to, amount) : amount;

        _balances[to] += finalAmount;

        emit Transfer(from, to, finalAmount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "MPEToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "MPEToken: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "MPEToken: burn amount exceeds balance");

        _balances[account] = accountBalance - amount;

        _baseBurn(account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "MPEToken: approve from the zero address");
        require(spender != address(0), "MPEToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "MPEToken: insufficient allowance");

            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _tradeControl(address from, address to) view private {
        if (from == address(uniswapV2PairIMAU) || to == address(uniswapV2PairIMAU)
        || from == address(uniswapV2PairBNB) || to == address(uniswapV2PairBNB)
        || from == address(uniswapV2PairUSDT) || to == address(uniswapV2PairUSDT)
        ) {
            address addr = (from == address(uniswapV2PairIMAU) || from == address(uniswapV2PairBNB) || from == address(uniswapV2PairUSDT)) ? to : from;
            if (excluded[addr]) {
                return;
            }

            if (startTime > block.timestamp) {

                revert("MPEToken: transaction not started");

            }
        }
    }

    function _fee(address from, address to, uint256 amount) private returns (uint256 finalAmount) {
        if (from == address(uniswapV2PairIMAU) || to == address(uniswapV2PairIMAU)) {
            address addr = from == address(uniswapV2PairIMAU) ? to : from;
            if (excluded[addr]) {
                finalAmount = amount;
            } else {
                finalAmount = _countFee(from, amount);
            }
        } else {
            finalAmount = amount;
        }
    }

    function _countFee(address from, uint256 amount) private returns (uint256 finalAmount) {
        uint256 daoFundFee = amount * daoFundRate / 1000;
        uint256 burnFee = amount * burnRate / 1000;

        if (_totalSupply == minTotalSupply) {
            burnFee = 0;
        }

        finalAmount = amount - daoFundFee - burnFee;

        _addBalance(from, daoFund, daoFundFee);

        if (burnFee > 0) {
            _baseBurn(from, burnFee);
        }
    }

    function _baseBurn(address from, uint256 amount) private {
        uint256 finalBurn = 0;
        if (_totalSupply > minTotalSupply) {
            finalBurn = amount;
            if (_totalSupply - amount < minTotalSupply) {
                finalBurn = _totalSupply - minTotalSupply;
            }
            _totalSupply -= finalBurn;
            burnTotalSupply += finalBurn;
            emit Transfer(from, address(0), finalBurn);
        }

        if (finalBurn < amount) {
            _addBalance(from, daoFund, amount - finalBurn);
        }
    }

    function _addBalance(address from, address to, uint256 amount) private {
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _baseTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "MPEToken: transfer from the zero address");
        require(to != address(0), "MPEToken: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "MPEToken: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}