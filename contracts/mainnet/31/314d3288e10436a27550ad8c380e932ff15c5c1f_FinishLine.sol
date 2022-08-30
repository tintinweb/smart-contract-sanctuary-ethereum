/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDEX_FACTORY {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEX_ROUTER {
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

contract FinishLine{
    
    IDEX_ROUTER private _router;
    address private _owner = address(0);
    address private _creator;
    address private _marketing = 0x2138D9D471a5CAF0F3D4a577dEe83852b607276B;
    address private _liquidity;
    string private _name = "Finish Line";
    string private _symbol = "Finish Line";
    uint8 private _decimals = 2;
    uint256 private _maxSupply;
    uint8 private _forLiquidity = 40;
    uint8 private _tax = 5;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    bool private _enabled;
    bool private _swapping;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Error(string message);

    modifier swapping(){
        _swapping = true;
        _;
        _swapping = false;
    }

    receive() external payable{
        if(msg.sender == _creator){
            if(_balances[address(this)] > 0 && address(this).balance > 0){
                _liquidity = IDEX_FACTORY(_router.factory()).createPair(address(this), _router.WETH());
                _router.addLiquidityETH{value:address(this).balance}(
                    address(this),
                    _balances[address(this)] / 100 * _forLiquidity,
                    0,
                    0,
                    _creator,
                    block.timestamp
                );
                if(_balances[address(this)] > 0){
                    _update(address(this), _creator, _balances[address(this)]);
                }
                _enabled = true;
            }
        }
    }

    constructor(){
        _creator = msg.sender;
        _router = IDEX_ROUTER(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_router)] = 2**256 - 1;
        _update(address(0), address(this), 1*10**9 * (10**_decimals));
        _excluded[address(this)] = true; _excluded[msg.sender] = true; _excluded[address(_router)] = true;
    }

    function taxes(uint8 tax) external{
        require(msg.sender == _creator);
        require(tax <= 25);
        _tax = tax;
    }

    function creator() external view returns(address){
        return(_creator);
    }

    function owner() external view returns(address){
        return(_owner);
    }

    function name() external view returns(string memory){
        return(_name);
    }

    function symbol() external view returns(string memory){
        return(_symbol);
    }

    function decimals() external view returns(uint8){
        return(_decimals);
    }

    function totalSupply() external view returns(uint256){
        return(_maxSupply);
    }

    function balanceOf(address wallet) external view returns(uint256){
        return(_balances[wallet]);        
    }

    function allowance(address from, address to) external view returns(uint256){
        return(_allowances[from][to]);
    }

    function transfer(address to, uint256 amount) external returns(bool){
        require(amount > 0);
        require(_balances[msg.sender] >= amount);
        _transfer(msg.sender, to, amount);
        return(true);
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool){
        require(amount > 0);
        require(_balances[from] >= amount);
        require(_allowances[from][msg.sender] >= amount);
        _transfer(from, to, amount);
        return(true);
    }

    function approve(address to, uint256 amount) external returns(bool){
        _allowances[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return(true);
    }

    function _transfer(address from, address to, uint256 amount) private{
        if(_excluded[from] || _excluded[to]){
            _update(from, to, amount);
        }else{
            require(_enabled);
            if(from == _liquidity){
                _transferTaxes(from, to, amount);
            }else if(to == _liquidity){
                _transferTaxes(from, to, amount);
            }else{
                _update(from, to, amount);
            }
        }
    }

    function _transferTaxes(address from, address to, uint256 amount) private{
        uint256 taxation = (amount * _tax)/100;
        _update(from, address(this), taxation);
        if(from != _liquidity && !_swapping){
            _swap();
        }
        _update(from, to, amount - taxation);
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

    function _swap() private swapping returns(bool){
        if(_balances[address(this)] > 0){
            address[] memory path = new address[](2); path[0] = address(this); path[1] = _router.WETH();
            try _router.swapExactTokensForETH(_balances[address(this)], 0, path, _marketing, block.timestamp) returns (uint256[] memory amounts){
                if(amounts[amounts.length - 1] > 0){
                    return(true);
                }
            }catch Error(string memory error){
                emit Error(error);
            }
        }
        return(false);
    }
}