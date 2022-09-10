/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

 interface ERC20Interface {
   event Transfer(address indexed from, address indexed to, uint tokens);
   event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

   function totalSupply() external returns(uint);
   function balanceOf(address tokenOwner) external returns (uint balance);
   function transfer(address to, uint tokens) external returns (bool success);
   function transferFrom(address from, address to, uint tokens) external returns (bool success);
   function approve(address spender, uint tokens) external returns (bool success);
   function allowance(address tokenOwner, address spender) external returns (uint remaining);
 }

contract Erc20 is ERC20Interface {
    string public constant name = "MyToken";
    string public constant symbol = "MTK";
    uint8 public constant decimals = 18;

    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    constructor(uint256 amount) {
        _balances[msg.sender] = amount;
        _totalSupply = amount;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner)
        public view 
        override
        returns (uint balance)
    {
        return _balances[tokenOwner];
    }

    function transfer(address to, uint tokens)
        external
        override
        returns (bool success) {
        return this.transferFrom(msg.sender, to, tokens);
    }

    function transferFrom(
        address from,
        address to,
        uint tokens
    ) external override returns (bool success) {
        require(to != address(0), "Can't send to address 0.");
        require(tokens > 0, "Can't send 0 tokens.");
        require(_balances[from] > tokens, "Insufficient funds.");

        _balances[msg.sender] = _balances[msg.sender] - tokens;
        _balances[to] = _balances[to] + tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function approve(address spender, uint tokens)
        external
        override
        returns (bool success)
    {
        _allowances[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint remaining)
    {
        return _allowances[tokenOwner][spender];
    }
}