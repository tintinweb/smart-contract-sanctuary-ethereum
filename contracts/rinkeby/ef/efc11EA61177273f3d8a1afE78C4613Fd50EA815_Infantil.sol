/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Infantil {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply_;
    
    constructor(uint256 total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    function symbol() public view returns(string memory) {
        return "INF";
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Tokens to send should be less or equal to balance.");

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);

        emit Transfer(msg.sender, receiver, numTokens);

        return true;
    }

    function approve(address spender, uint tokens) payable public returns (bool) {
        allowed[msg.sender][spender] = msg.value;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        require(tokens <= balances[from], "Tokens to transfer should be less or eqaul to balance of owner.");
        require(allowed[from][to] >= tokens, "Allowed tokens to send should be less or equal.");

        balances[from] = balances[from].sub(tokens);
        balances[to] += balances[to].add(tokens);

        allowed[from][to] = allowed[from][to].sub(tokens);

        emit Transfer(from, to, tokens);

        return true;
    }
}