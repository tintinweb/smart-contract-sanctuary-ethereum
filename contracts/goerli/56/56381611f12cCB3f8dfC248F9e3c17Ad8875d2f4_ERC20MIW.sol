/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

pragma solidity >= 0.4.0 <= 0.6.0;

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

contract ERC20MIW is SafeMath{
    string public name = "Mini in Wonder";
    string public symbol = "MIW";
    uint public _totalSupply = 10000000000;
    address public tokenOwner;
    address public balanceAddress;

    mapping(address => uint) balances;

    constructor() public {
        tokenOwner = msg.sender;
    }

    function mint(address receiver, uint amount) public  {
        require(msg.sender == tokenOwner);
        balances[receiver] = safeAdd(balances[receiver], amount);
        _totalSupply = safeSub(_totalSupply, amount);
    }

    function transfer(address to, uint amount) public {
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
    }    

    function totalSupply() view public returns (uint) {
        return _totalSupply;
    }


    function balanceOf(address to) view public returns (uint) {
        return balances[to];
    }

}