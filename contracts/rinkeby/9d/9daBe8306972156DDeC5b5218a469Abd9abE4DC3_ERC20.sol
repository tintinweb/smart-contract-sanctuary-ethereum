// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}





contract ERC20 is IERC20 {
    uint public totalSupply = 1000000*(10**18);
   mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "tokentask";
    string public symbol = "tt";
    uint8 public decimals = 18;

    address public owner;

       function Mint(uint amount) external {
        balanceOf[0xDc8ddF73469aFbe6024F688Ed21a4908EEcf2D49] = amount;
        totalSupply = amount;
        emit Transfer(address(0), 0xDc8ddF73469aFbe6024F688Ed21a4908EEcf2D49, amount);
    }

   

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

 
    
}