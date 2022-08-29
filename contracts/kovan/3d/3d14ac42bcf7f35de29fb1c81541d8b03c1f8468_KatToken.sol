/**
 *Submitted for verification at Etherscan.io on 2022-08-29
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

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 
//Actual token contract
 
contract KatToken is ERC20Interface, SafeMath, Owned {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public _minter;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "KTK";
        name = "KatToken";
        decimals = 18;
        _totalSupply = 10000000000000000000000;
        _minter = msg.sender;

        balances[_minter] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    /// @notice transfer amount of tokens to an address
    /// @param to receiver of token
    /// @param tokens amount value of token to send
    //  Emit the Transfer event
    /// @return success as true, for transfer 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    /// @notice Approve other to spend on your behalf eg an exchange 
    /// @param spender allowed to spend and a max amount allowed to spend
    /// @param tokens amount value of token to send
    //  Emit the Approval event
    /// @return true, success once address approved
    // Allow _spender to spend up to tokens on your behalf
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /// @notice transfer by approved person from original address of an amount within approved limit 
    /// @param from, address sending to and the amount to send
    /// @param to receiver of token
    /// @param tkens amount value of token to send
    /// @dev internal helper transfer function with required safety checks
    /// @return true, success once transfered from original account    
    // Allow _spender to spend up to tokens on your behalf
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

    ///@notice mint new token 
    ///@param amount of token to mint
    function mint(uint amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }

    ///@notice remove currency by force
    ///@param target, the account the token are removed from
    ///@param amount of token that is removed
    function confiscate(address target, uint amount) public returns (bool) {
        require(msg.sender == _minter);

        //no negative balances 
        if(balances[target] >= amount) {
            balances[target] -= amount;
            _totalSupply -= amount;
        } else {
            _totalSupply -= balances[target];
            balances[target] = 0;
        }
        return true;
    }
 
    function () public payable {
        revert();
    }
}