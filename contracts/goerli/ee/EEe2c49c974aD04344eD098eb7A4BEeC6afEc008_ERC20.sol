/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    // the event of changing the value of the permissions dictionary
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Returns the number of tokens that the spender can spend from the address owner
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    // granting the spender address permission to spend amount of tokens from msg.sender address
    function approve(address spender, uint256 amount) external returns (bool);

    // sending amount of tokens to to address from msg.sender
    function transfer(address to, uint256 amount) external returns (bool);

    // Send a token amount to the to address from the from address
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ERC20 is IERC20 {
    string public constant name = "Der beste Token in der gesamten Blockchain";
    string public constant symbol = "BTIB";
    uint8 public constant decimals = 2;

    uint256 public totalSupply;
    address immutable _owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        _owner = msg.sender;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender==_owner, "ERC20: You are not owner");
        balances[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: not enough tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(allowed[msg.sender][from] >= amount, "ERC20: no permission to spend");
        require(balances[from] >= amount, "ERC20: not enough tokens");
        balances[from] -= amount;
        balances[to] += amount;
        allowed[msg.sender][from] -= amount;
        emit Approval(msg.sender, from, allowed[msg.sender][from]);
        return true;
    }
}