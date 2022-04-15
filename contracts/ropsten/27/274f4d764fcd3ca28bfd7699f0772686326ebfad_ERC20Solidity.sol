/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.5.0;

// ERC Token Standard #20 Interfacep

contract ERC20 {
    function supply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transferTo(address to, uint tokens) public returns (bool success);
    function approved(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// Math Library

contract Math {
    function safeAdd(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function safeSub(uint x, uint y) public pure returns (uint z) {
        require(y <= x); z = x - y; } function safeMul(uint x, uint y) public pure returns (uint z) { z = x * y; require(x == 0 || z / x == y); } function safeDiv(uint x, uint y) public pure returns (uint z) { require(y > 0);
        z = x / y;
    }
}


contract ERC20Solidity is ERC20, Math {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _supply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        name = "Prabhu";
        symbol = "EKY";
        decimals = 18;
        _supply = 100000000000000000000000000;

        balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    function supply() public view returns (uint) {
        return _supply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approved(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferTo(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}