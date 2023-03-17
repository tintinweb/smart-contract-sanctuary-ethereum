/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ERC20 Token standard Interface
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint amount) external returns (bool success);
    function approve(address spender, uint amount) external returns (bool success);
    function transferFrom(address from, address to, uint amount) external returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    event Rebase(uint totalSupply);
}

// Token Contract
contract RebaseToken is ERC20Interface {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal,
        uint totalSupply_
    ) {
        symbol = _symbol;
        name = _name;
        decimals = _decimal;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view returns (uint balance) {
        return balances[account];
    }
 
    function transfer(address to, uint amount) public returns (bool success) {
        require(balances[msg.sender] >= amount);
        _transfer(msg.sender, to, amount);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Ensure sending is to valid address! 0x0 address can be used to burn() 
        require(_to != address(0));
        balances[_from] = balances[_from] - (_value);
        balances[_to] = balances[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
 
    function approve(address spender, uint amount) public returns (bool success) {
        require(spender != address(0));
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        require(amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
        _transfer(msg.sender, to, amount);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function mint(address account, uint amount) external {
        require(account != address(0), "Token: mint to the zero address");
        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint amount) external {
        require(account != address(0), "Token: mint to the zero address");
        balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function rebase(uint totalValue) external returns (bool success) {
        uint oldSupply = _totalSupply;
        uint newSupply = totalValue;
        _totalSupply = newSupply;
        emit Rebase(newSupply);

        if (oldSupply < newSupply) {
            uint diff = newSupply - oldSupply;
            balances[msg.sender] += diff;
        } else {
            uint diff = oldSupply - newSupply;
            balances[msg.sender] -= diff;
        }

        return true;
    }
 
}