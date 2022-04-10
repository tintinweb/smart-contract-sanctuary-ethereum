/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// File: Insurance.sol

pragma solidity ^0.5.0;



contract ERC20Interface {

    function totalSupply() public view returns (uint);
    function returnPremium() public view returns (uint);


    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function burn(uint256 value) public returns (bool success);
    
    function burnfrom(address from, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function collectInsuranceFunds(address from) public returns (bool success);

    function TestifInsurable(uint age, uint ChildrenCovered) public returns (uint);

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

 

 

contract InsuranceBasicToken is ERC20Interface, SafeMath {

    string public name;

    string public symbol;

    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public premium; // base premium

    address public InsuranceAddress; 

    uint256 public _totalSupply;

 

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;


    /**

     * Constrctor function

     *

     * Initializes contract with initial supply tokens to the creator of the contract

     */

    constructor() public {

        name = "NeoHealth";

        symbol = "NEOH";

        decimals = 18;

        _totalSupply = 100000000000000000000000000;

        premium = 7500;

        InsuranceAddress = 0x1154c78e66ca0289639d9e20b31E813a4AE5f3C9;

        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

    }

 

    function totalSupply() public view returns (uint) {

        return _totalSupply  - balances[address(0)];

    }

 
    function returnPremium() public view returns (uint) {

        return premium;

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
    function collectInsuranceFunds(address from) public returns (bool success)
    {
        balances[from] = safeSub(balances[from], premium);

        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], premium);

        balances[InsuranceAddress] = safeAdd(balances[InsuranceAddress], premium);

        emit Transfer(from, InsuranceAddress, premium);
        return true; 
    }
    function burn(uint256 value) public returns (bool success){
        require(balances[msg.sender] >= value);
        
        balances[msg.sender] -= value;
        
        _totalSupply -= value;
        return true;
    }
    function burnfrom(address from, uint256 value) public returns (bool success)
    {
        require(balances[from] >= value);
        require(value <= allowed[from][msg.sender]);
        
        balances[from] -= value;
        _totalSupply -= value;
        return true;
    }
    function TestifInsurable(uint age, uint ChildrenCovered) public returns (uint)
    {
        bool Young = false;
        bool Old = false;
        if(age < 30)
        {
            Young = true; 
        }
        if(age > 65)
        {
            Old = true;
        }

        uint costPerChild = 2500;
        if (Young) {
            premium *= 2;
        }
        if (Old) {
            premium *= 3;
        }

        premium += costPerChild * ChildrenCovered;
        return premium;
    }
}