/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
// --------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20

// Only mandatory functions are first 3!


interface ERC20Interface {
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract Cryptos is ERC20Interface {
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; // 18
    uint public override totalSupply;

    address public founder;

    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowed;

    // 0x1111. (owner) allows 0x2222... (the spender) 0x12321 to spend 1000 token
    // allowed[0x1111][0x12321] = 1000;

    constructor() {
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns(bool success) {
        require(balances[msg.sender] >= tokens);

        balances[to] += tokens;
        balances[msg.sender] -= tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view override returns(uint) { // returns the amount spender still allowed to spent
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns(bool success) {

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);

        return true;

    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens; 
        balances[to] += tokens;

        emit Transfer(from, to, tokens);
        return true;
    }

}