/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);    //get the total token supply
    function balanceOf(address account) external view returns (uint);   //get the account balance of account address
    function transfer(address recipient, uint amount) external returns (bool);  //send amount of tokens
    function approve(address spender, uint amount) external returns (bool);     //allow tokens to be withdrawn from sending address
    function allowance(address owner, address spender) external view returns (uint);    //returns the remaining tokens of the address
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);  //define where the tokens are transfering from
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// Iris create her novel as a ERC20 standard token. Named "MyBook"
contract MyBook is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "IRIS BOOK";
    string public symbol = "IBK";
    uint8 public decimals = 18;

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

    function mint(uint amount) external {
    	//require( msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,"you are not creator");
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}