/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
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
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// The token contract
// ----------------------------------------------------------------------------
contract HaimAndDanielCoin is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    // This mapping is where we store the balances of an address
    mapping(address => uint) balances;
    // This is a mapping of a mapping
    // This is for the approval function to determine how much an address can spend
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Haim And Daniel Coin";
        symbol = "HAD";
        decimals = 18;
        //1,000,000 + 18 zeros
        _totalSupply = 1000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // Constant value that does not change
    // returns the amount of initial tokens to display
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    // Returns the balance of a specific address
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Allows a spender address to spend a specific amount of tokens
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Transfer an amount of tokens to another address.  The transfer needs to be > 0 
    // Does the msg.sender have enough tokens to forfill the transfer
    // Decrease the balance of the sender, and increase the balance of the "to" address
    function transfer(address to, uint tokens) public returns (bool success) {
        if (tokens > 0 && tokens <= balanceOf(msg.sender)) {
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }
        return false;
    }

    // This allows someone else (a 3rd party) to transfer from my wallet to someone elses wallet
    // If the 3rd party has an allowance of > 0 
    // And the value to transfer is > 0 
    // And the allowance is >= the value of the transfer
    // And it is not a contract
    // Perform the transfer by increasing the to account, and decreasing the "from" accounts
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}