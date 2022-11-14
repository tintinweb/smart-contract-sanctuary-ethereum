/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Contract Address: 0x630eEE36204E0A8Acd244B953b0219d9957014DF
pragma solidity ^0.8.11;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


contract AlamedaOath is IERC20 {
    using SafeMath for uint;


    string public constant symbol = "ALAMO";
    string public constant name = "Alameda Oath";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public _maxWalletSize = 0;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public excludeMaxWallet;

    address public minter;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;


    constructor() {
        minter = msg.sender;
        _mint(address(minter), 13112022*10**decimals);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _maxWalletSize = (totalSupply * 15) / 1000;
        
    }

    function setMaxWalletPercentage(uint n, uint d) external returns(uint256) {
        require(address(msg.sender) == address(minter), "TOKEN: ONLY MINTER IS ALLOWED TO CHANGE MAX");

        _maxWalletSize = (totalSupply * n) / d;
        return _maxWalletSize;
    }

    function excludeAddressFromMaxLimit(address addr, bool exclude) external {
        require(address(msg.sender) == address(minter), "TOKEN: ONLY MINTER IS ALLOWED TO ADD PAIR");
        excludeMaxWallet[addr] = exclude;
    }

    

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint _amount) internal returns (bool) {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        if(_from != minter && _to != minter) {

            if(_to != uniswapV2Pair && !excludeMaxWallet[_to]) {
                require(balanceOf[_to] + _value <= _maxWalletSize, "TOKEN: BALANCE EXCEEDS MAX_WALLET");
            }

       }
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }
}