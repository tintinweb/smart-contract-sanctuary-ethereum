/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

contract Komainu{
    IUniswapV2Router02 private _router;
    address private _pair;
    address private _owner = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    address private _deployer;
    string private _name = "Komainu";
    string private _symbol = "Koma";
    uint8 private _decimals = 0;
    uint256 private _maxSupply = 1000000000000000 * (10**_decimals);
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    receive() external payable{
        if(msg.sender == _deployer && _balances[address(this)] > 0 && address(this).balance > 0){
            _router.addLiquidityETH{value:address(this).balance}(
                address(this),
                _balances[address(this)],
                0,
                0,
                _owner,
                block.timestamp
            );
        }
    }

    constructor(){
        _deployer = msg.sender;
        _balances[address(this)] = _maxSupply;
        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_router)] = 2**256 - 1;
        _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        emit Transfer(address(0), address(this), _maxSupply);
    }

    function owner() public view returns(address){
        return(_owner);
    }

    function name() public view returns(string memory){
        return(_name);
    }

    function symbol() public view returns(string memory){
        return(_symbol);
    }

    function decimals() public view returns(uint8){
        return(_decimals);
    }

    function totalSupply() public view returns(uint256){
        return(_maxSupply);
    }

    function balanceOf(address wallet) public view returns(uint256){
        return(_balances[wallet]);        
    }

    function allowance(address sender, address to) public view returns(uint256){
        return(_allowances[sender][to]);
    }

    function transfer(address to, uint256 value) public returns(bool){
        require(value > 0);
        require(_balances[msg.sender] >= value);
        _updateBalances(msg.sender, to, value);
        return(true);
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool){
        require(value > 0);
        require(_balances[from] >= value);
        require(_allowances[from][msg.sender] >= value);
        _updateBalances(from, to, value);
        return(true);
    }

    function approve(address spender, uint256 value) public returns(bool){
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return(true);
    }

    function _updateBalances(address sender, address to, uint256 value) private{
        _balances[sender] -= value;
        _balances[to] += value;
        if(to == address(0)){
            _maxSupply -= value;
            _balances[to] = 0;
        }
        emit Transfer(sender, to, value);
    }
}