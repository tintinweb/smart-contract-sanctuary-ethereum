/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// File: contracts/SuperERC20.sol



pragma solidity ^0.8.0;


contract Super_ERC20{
    uint256 public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name;
    string public symbol;
    address public owner;

    constructor(string memory _name, string memory _symbol) public {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
    }


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    function _name() external view returns (string memory){
        return name;
    }

    function _symbol() external view returns (string memory){
        return symbol;
    }

    function _totalSupply() external view returns (uint){
        return totalSupply;
    }

    function _balanceOf(address account) external view returns (uint){
        return balanceOf[account];
    }

    function transfer(address to, uint256 amount) external returns (bool){
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0),msg.sender,amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -=amount;
        totalSupply -= amount;
        emit Transfer(msg.sender,address(0),amount);
    }
}