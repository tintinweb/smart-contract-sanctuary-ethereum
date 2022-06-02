/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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

contract Cypherpunk{
    
    IUniswapV2Router01 private _router;
    address private _owner = address(0);
    address private _deployer;
    string private _name = "Cypherpunk";
    string private _symbol = "CPNK";
    uint8 private _decimals = 2;
    uint256 private _maxSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    bool private _enabled;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    receive() external payable{
        if(msg.sender == _deployer){
            if(_balances[address(this)] > 0 && address(this).balance > 0){
                _router.addLiquidityETH{value:address(this).balance}(
                    address(this),
                    _balances[address(this)],
                    0,
                    0,
                    address(0),
                    block.timestamp
                );
            }else if(msg.value <= 0){
                _enabled = true;
            }
        }
    }

    constructor(){
        _deployer = msg.sender;
        _router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_router)] = 2**256 - 1;
        IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        _update(address(0), address(this), (1952020219440605*(10**_decimals))/100*49);
        _update(address(0), 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B, (1952020219440605*(10**_decimals))/100*51);
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

    function allowance(address from, address to) public view returns(uint256){
        return(_allowances[from][to]);
    }

    function transfer(address to, uint256 amount) public returns(bool){
        require(amount > 0);
        require(_balances[msg.sender] >= amount);
        _transfer(msg.sender, to, amount);
        return(true);
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool){
        require(amount > 0);
        require(_balances[from] >= amount);
        require(_allowances[from][msg.sender] >= amount);
        _transfer(from, to, amount);
        return(true);
    }

    function approve(address to, uint256 amount) public returns(bool){
        _allowances[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return(true);
    }

    function _transfer(address from, address to, uint256 amount) private{
        if(from == address(this) || to == address(this)){
            _update(from, to, amount);
        }else{
            require(_enabled);
            _update(from, to, amount);
        }
    }

    function _update(address from, address to, uint256 amount) private{
        if(from != address(0)){
            _balances[from] -= amount;
        }else{
            _maxSupply += amount;
        }
        if(to == address(0)){
            _maxSupply -= amount;
        }else{
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}