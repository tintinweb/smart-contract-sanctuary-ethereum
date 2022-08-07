/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

pragma solidity ^0.8.0;

contract Token{
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);
    
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }
    
    function _transfer(address from, address to, uint256 amount) internal{
        require(to != address(0) && from != to, "ERC20:invalid to");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    function _approve(address from, address to, uint256 amount) internal{
        require(to != address(0) && from != to, "ERC20:invalid to");
        allowance[from][to] = amount;
        emit Approval(from, to, amount);
    }
    
    function transfer(address to, uint256 amount) external{
        _transfer(msg.sender, to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) external{
        _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        _transfer(from, to, amount);
    }
    
    function approve(address to, uint256 amount) external{
        _approve(msg.sender, to, amount);
    }
    
    function mint(uint256 amount) external{
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}