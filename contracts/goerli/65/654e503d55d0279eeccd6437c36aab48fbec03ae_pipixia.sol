/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
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
    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
    if (a == 0) {
    return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
    }
    function div(uint256 a, uint256 b) public pure returns (uint256) {
        if (b == 0) {
    return 0;
    }
        return div(a, b);
    }
}


contract pipixia is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    address public deadwallet = 0x0000000000000000000000000000000000000000;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "pipixia";
        symbol = "PPX";
        decimals = 18;
        _totalSupply = 10000000* (10 ** 18);

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transfer(address to, uint tokens) public returns (bool success) {
       
        uint256 BurnWallet = div(mul(tokens,5),100);    //每次交易销毁百分之5
        uint256 trueAmount = safeSub(tokens,BurnWallet);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], trueAmount);
        emit Transfer(msg.sender, deadwallet, BurnWallet);
        emit Transfer(msg.sender, to, trueAmount);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint256 BurnWallet = div(mul(tokens,5),100);    //每次交易销毁百分之5
        uint256 trueAmount = safeSub(tokens,BurnWallet);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], trueAmount);
        emit Transfer(from, deadwallet, BurnWallet);
        emit Transfer(from, to, trueAmount);
        return true;
    }


}