/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract SafeMath {
 
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address owner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint remaining);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed owner, address indexed spender, uint tokens);
}
 
contract ApproveAndCallFallBack {
    function getApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
contract myOwnToken02 is ERC20Interface, SafeMath {
    uint    public _totalSupply;
    string  public  name;
    string  public symbol;
    uint8   public decimals;
    address public manager;
    uint    private maxSlots;

    struct Meeting { 
      bool free;
      string date;
      string topic;
      string email;      
    }
 
    Meeting[4] public schedule;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        manager = msg.sender;
        name = "myOwnToken03";
        symbol = "MOT3";
        decimals = 0;
        maxSlots = 4;
        _totalSupply = 100;
        balances[manager] = _totalSupply;
        
        schedule[0].free = true;
        schedule[0].date = 'June 14 2022 7:00 PM MSC';

        schedule[1].free = true;
        schedule[1].date = 'June 16 2022 7:00 PM MSC';

        schedule[2].free = true;
        schedule[2].date = 'June 21 2022 7:00 PM MSC';

        schedule[3].free = true;
        schedule[3].date = 'June 23 2022 7:00 PM MSC';                

        emit Transfer(address(0), manager, _totalSupply);
    }
 
    modifier restricted() {
        require (msg.sender == manager);
        _;
    }

    function setSchedule(uint slot, string memory date, string memory topic, string memory email) public restricted {
        require (slot >= 0 && slot < maxSlots, "Incorrect slot");

        schedule[slot].date = date;
        schedule[slot].topic = topic;
        schedule[slot].email = email;
        
        return;
    }

    function setMeeting(uint slot, string memory topic, string memory email) public {
        require (balances[msg.sender] > 0, "Not enough tokens");
        require (slot >= 0 && slot < maxSlots, "Incorrect slot"); 
        require (schedule[slot].free == true, "slot is already occupied");
        require (bytes(topic).length > 0, "Please set up a topic");
        require (bytes(email).length > 0, "Please add your email");

        balances[msg.sender] = sub(balances[msg.sender], 1);
        balances[manager] = add(balances[manager], 1);
        schedule[slot].free = false;
        schedule[slot].topic = topic;
        schedule[slot].email = email;

        return;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address owner) public constant returns (uint balance) {
        return balances [owner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = sub(balances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function allowance(address owner, address spender) public constant returns (uint remaining) {
        return allowed[owner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).getApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }
}