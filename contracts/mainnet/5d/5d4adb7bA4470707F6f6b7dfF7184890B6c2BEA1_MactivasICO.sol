/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MactivasICO is IERC20 {
    string public constant name = "MactivasICO";
    string public constant symbol = "MACT ICO";
    uint8 public constant decimals = 18;
    uint256 totalSupply_ = 200000000000000000000000000;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address MactP_Owner)
        public
        view
        
        returns (uint256)
    {
        return balances[MactP_Owner];
    }

    function transfer(address _to, uint256 amount)
        public
        
        returns (bool)
    {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[_to] = balances[_to] + amount;
        emit Transfer(msg.sender, _to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public  returns (bool) {
        require(amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);

        balances[from] = balances[from] - amount;
        allowed[from][msg.sender] = allowed[from][msg.sender] + amount;
        balances[to] = balances[to] + amount;
        emit Transfer(from, to, amount);
        return true;
    }
}