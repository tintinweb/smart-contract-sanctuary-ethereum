/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity ^0.4.24;

 
 
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
 
contract SSHackToken is ERC20Interface {
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
    }
 
    function totalSupply() public constant returns (uint) {
        return 3;
    }
 
    function balanceOf(address) public constant returns (uint balance) {
        return 1;
    }
 
    function transfer(address, uint) public returns (bool success) {
        emit Transfer(msg.sender, msg.sender, 1);
        return true;
    }
 
    function approve(address, uint) public returns (bool success) {
        emit Approval(msg.sender, msg.sender, 2);
        return true;
    }
 
    function transferFrom(address, address, uint) public returns (bool success) {
        emit Transfer(msg.sender, msg.sender, 1);
        return true;
    }
 
    function allowance(address, address) public constant returns (uint remaining) {
        return 2;
    }
 
    function () public payable {
        revert();
    }
}