/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Proxy {
    function prox_Transfer(address from, address to, uint256 amount) virtual public;
    function prox_balanceOf(address who) virtual public view returns (uint256);
    function prox_setup(address token, uint256 supply) virtual public returns (bool);
}

contract TestToken {
    
    string public constant name = "Simple";
    string public constant symbol = "SM";
    uint256 totalSupply_;
    address private Proxy_address;
    uint8 public constant decimals = 18;
    mapping(address => mapping (address => uint256)) allowed;
    address private deployer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _prox)  {
        deployer = msg.sender;
        Proxy_address = _prox;
        totalSupply_ = 10000000*10**18;
        Proxy(Proxy_address).prox_setup(address(this), totalSupply_);
    }

        function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return Proxy(Proxy_address).prox_balanceOf(tokenOwner);
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        Proxy(Proxy_address).prox_Transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowed[from][msg.sender]>=amount, "Not allowed");
        Proxy(Proxy_address).prox_Transfer(from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
}