/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    //total supply of token
    function totalSupply() external view returns (uint);

    //balance of provided address
    function balanceOf(address account) external view returns (uint);

    //token holder calling transfer to send tokens to recipient
    function transfer(address recipient, uint amount) external returns (bool);

    //balance sender can spend of some owner tokens 
    function allowance(address owner, address spender) external view returns (uint);

    //token holder approving the spender to spend his tokens up to amount
    function approve(address spender, uint amount) external returns (bool);

    //sender can send tokens of recipiend, in amount recipient approve earlier
    function transferFrom(address sender,  address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is IERC20{

    uint public totalSupply;
    mapping (address=>uint) public balanceOf;
    mapping (address=> mapping(address=>uint)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;
    address owner;

    constructor(/*string memory _name, string memory _SYMBOL, uint8 _decimals, uint _totalSupply*/){
        name = "Token";
        symbol = "TOKEN";
        decimals = 9;
        totalSupply = 1000 * 10 ** decimals;
        owner = msg.sender;
        balanceOf[owner]+=totalSupply;   
        emit Transfer(address(0), owner, totalSupply);
    }

    function beforeTransfer(uint _senderBal,  uint amount) internal pure{
        require(_senderBal>=amount,"ERROR");
    }

    function transfer(address recipient, uint amount) external returns (bool){
        beforeTransfer(balanceOf[msg.sender], amount);
        balanceOf[msg.sender]-=amount;
        balanceOf[recipient]+=amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender,  address recipient, uint amount) external returns (bool){
        beforeTransfer(balanceOf[sender], amount);
        allowance[sender][msg.sender]-= amount;
        balanceOf[sender]-=amount;
        balanceOf[recipient]+=amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external{
        balanceOf[msg.sender] += amount;
        totalSupply +=amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external{
        balanceOf[msg.sender] -= amount;
        totalSupply -=amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}