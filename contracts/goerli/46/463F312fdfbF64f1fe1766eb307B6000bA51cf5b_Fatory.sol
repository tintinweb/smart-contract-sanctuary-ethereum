/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function mint() external;
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20 {
    mapping (address => bool) public _isMint;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Solidity";
    string public symbol = "Sol";
    uint8 public decimals = 18;
    uint public totalSupply;

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

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint() external {
        uint amount = 1E19;
        require(_isMint[msg.sender] == false, "has mint");
        _isMint[msg.sender]=true;
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}

contract Mint {    
    constructor(address Sol, address owner) {
        IERC20(Sol).mint();
        uint balances = IERC20(Sol).balanceOf(address(this));
        IERC20(Sol).transfer(owner, balances);
        selfdestruct(payable(owner));
    }
}

contract Fatory {
    address public Sol;
    address public owner;
    
    constructor(address sol) {
        Sol = sol;
        owner = msg.sender;
    }

    function start(uint count) external {
        require(msg.sender == owner, "only owner");
        for (uint i=0; i<count; ++i) {
            new Mint(Sol, owner);
            }
    }
}