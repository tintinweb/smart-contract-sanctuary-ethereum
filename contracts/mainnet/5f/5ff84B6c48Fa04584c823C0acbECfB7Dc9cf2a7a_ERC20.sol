/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.8.0;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, address initAccount){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[initAccount] = totalSupply;
        emit Transfer(address(0), initAccount, totalSupply);
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    function transfer(address to, uint256 amount) external returns (bool){
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function _approve(address from, address to, uint256 amount) internal {
        allowance[from][to] = amount;
        emit Approval(from, to, amount);
    }
    
    function approve(address spender, uint256 amount) external returns (bool){
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        _transfer(from, to, amount);
        return true;
    }
}