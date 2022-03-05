/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

pragma solidity ^0.4.24;

//Safe Math Interface

contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


//ERC Token Standard #20 Interface

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


//Contract function to receive approval and execute function in one call

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

//Actual token contract

contract FrakToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "FRAK";
        name = "Fraktal";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        balances[0x80EEa8803120a4Aa95FD0d291E1CBe6Ce7c315A8] = 3000000000000000000000000;
        balances[0x362BFCE30b3DA37bf43cF8E50e177EE87B79d236] = 6000000000000000000000000;
        balances[0xbA7Ca3f921eAfE0De5B4C024A714067D28Da3fb3] = 2500000000000000000000000;
        balances[0x4C1596FBA63Fe1157E90cCC51d5548E0C78E9CB8] = 3500000000000000000000000;
        balances[0xA31b92E81318248958d8eaa691Cc8919ad7Af68F] = 7500000000000000000000000;
        balances[0xeCc90e132a4BBdd1e6165149437a95a6133F9A4a] = 14000000000000000000000000;
        balances[0x04BaEe1c44A982EAA7DaA6F63a7Bbc26cdc8D0C4] = 1500000000000000000000000;
        balances[0x71924C4A7fB2B9796C3f9125DA66a6F17f905667] = 4750000000000000000000000;
        balances[0x80943f01d7DA4Dc657eaeE1AFFB98CB7981E644d] = 7250000000000000000000000;
        balances[0xfe94655fe300C4961b05985FDE83c02672D3A8f1] = 950000000000000000000000000;
        emit Transfer(address(0), 0x80EEa8803120a4Aa95FD0d291E1CBe6Ce7c315A8 , 3000000000000000000000000);
        emit Transfer(address(1), 0x362BFCE30b3DA37bf43cF8E50e177EE87B79d236 , 6000000000000000000000000);
        emit Transfer(address(2), 0xbA7Ca3f921eAfE0De5B4C024A714067D28Da3fb3 , 2500000000000000000000000);
        emit Transfer(address(3), 0x4C1596FBA63Fe1157E90cCC51d5548E0C78E9CB8 , 3500000000000000000000000);
        emit Transfer(address(4), 0xA31b92E81318248958d8eaa691Cc8919ad7Af68F , 7500000000000000000000000);
        emit Transfer(address(5), 0xeCc90e132a4BBdd1e6165149437a95a6133F9A4a , 14000000000000000000000000);
        emit Transfer(address(6), 0x04BaEe1c44A982EAA7DaA6F63a7Bbc26cdc8D0C4 , 1500000000000000000000000);
        emit Transfer(address(7), 0x71924C4A7fB2B9796C3f9125DA66a6F17f905667 , 4750000000000000000000000);
        emit Transfer(address(8), 0x80943f01d7DA4Dc657eaeE1AFFB98CB7981E644d , 7250000000000000000000000);
        emit Transfer(address(9), 0xfe94655fe300C4961b05985FDE83c02672D3A8f1 , 950000000000000000000000000);

    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }
}