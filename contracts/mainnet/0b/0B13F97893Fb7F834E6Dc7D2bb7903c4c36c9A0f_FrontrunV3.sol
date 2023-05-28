/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
// Frontrun AI Token
/*

8888888888                        888                                           d8888 8888888 
888                               888                                          d88888   888   
888                               888                                         d88P888   888   
8888888 888d888  .d88b.  88888b.  888888 888d888 888  888 88888b.            d88P 888   888   
888     888P"   d88""88b 888 "88b 888    888P"   888  888 888 "88b          d88P  888   888   
888     888     888  888 888  888 888    888     888  888 888  888         d88P   888   888   
888     888     Y88..88P 888  888 Y88b.  888     Y88b 888 888  888        d8888888888   888   
888     888      "Y88P"  888  888  "Y888 888      "Y88888 888  888       d88P     888 8888888 

0100011001110010011011110110111001110100011100100111010101101110  0100000101001001   V. 0.36a                                                                                          
 */      

pragma solidity ^0.8.0;

contract FrontrunV3 {
    string public constant name = "Frontrun AI";
    string public constant symbol = "FRUN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    bool public paused;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused();
    event Unpaused();

    constructor() {
        totalSupply = 1e12 * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, allowances[from][msg.sender] - value);
        return true;
    }

    function approve(address spender, uint256 value) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Allowance insufficient");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function pause() external {
        require(!paused, "Contract is already paused");
        paused = true;
        emit Paused();
    }

    function unpause() external {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused();
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Transfer value must be greater than zero");
        require(balances[from] >= value, "Insufficient balance");

        balances[from] -= value;
        balances[to] += value;

        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");

        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
}