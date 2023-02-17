// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./INTDAO.sol";

contract Rule {
    string public constant name = "Rule token";
    string public constant symbol = "RULE";
    uint256 initialSupply;
    INTDAO dao;
    mapping (address => uint256) balances; //amount of tokens each address holds
    mapping (address => mapping (address => uint256)) allowed;


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burned(address from, uint256 value);
    event Mint(address to, uint256 value);

    constructor(address _INTDAOaddress){
        initialSupply += 10**6*10**18;
        balances[msg.sender] = initialSupply;
        dao = INTDAO(_INTDAOaddress);
        dao.setAddressOnce("rule", payable(address(this)));
    }

    function totalSupply() external virtual view returns (uint supply) {
        return initialSupply;
    }

    function balanceOf(address tokenHolder) public view returns (uint256 balance) {
        return balances[tokenHolder];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function mint(address to, uint256 amount) public returns (bool) {
        if (amount>10) require (msg.sender == dao.addresses('cdp'), 'only collateral contract is authorized to mint');
        balances[to] += amount;
        initialSupply += amount;
        emit Mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) public returns (bool success) {
        require (msg.sender == dao.addresses('cdp'), 'only collateral contract is authorized to burn');
        initialSupply -= amount;
        balances[from] -= amount;
        emit Burned(address(from), amount);
        return true;
    }
}