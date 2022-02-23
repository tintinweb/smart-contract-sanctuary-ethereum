/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.8.0;

contract WON {
    string constant public name = "Wonderful Tiger";
    string constant public symbol = "WON";
    uint8 constant public decimals = 18;
    uint256 constant public totalSupply = 1e27;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approve(address indexed owner, address indexed spender, uint256 amount);
    
    constructor(address account){
        balanceOf[account] = totalSupply;
        emit Transfer(address(0), account, totalSupply);
    }
    
    function transfer(address to, uint256 amount) external returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns(bool){
        allowance[msg.sender][spender] = amount;
        emit Approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns(bool){
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}