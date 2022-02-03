/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERC20Interface {
    // Standard ERC-20 interface.
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    //function totalSupply() external view returns (uint256);

    //function balanceOf(address who) external view returns (uint256);

    //function allowance(address owner, address spender) external view returns (uint256);

    // Extension of ERC-20 interface to support supply adjustment.
    function mint(address to, uint256 value) external returns (bool);

    function burn(address from, uint256 value) external returns (bool);
}

library SafeMath {

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert (c >= a && c >= b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }
}

contract MDD is ERC20Interface {

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowance;

    event TransferFrom(address indexed from, address indexed to, uint256 amount);
    event Approve(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, address indexed to, uint256 amount);
    event ChangeOwner(address indexed from, address indexed to);

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        totalSupply = totalSupply_;
        decimals = decimals_;

        balanceOf[msg.sender] = totalSupply_;
    }

    function changeOwner(address newOwner) external {
        assert(msg.sender == owner);
        assert(newOwner != owner && newOwner != address(0x0));

        address oldOwner = owner;
        owner = newOwner;
        emit ChangeOwner(oldOwner, newOwner);
    }


    function transfer(address to, uint256 value) external override returns (bool) {
        assert(to != address(0x0) && to != msg.sender);
        assert(value > 0);
        assert(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = SafeMath.safeAdd(balanceOf[to], value);

        emit TransferFrom(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        assert(spender != address(0x0));
        assert(value > 0);

        allowance[msg.sender][spender] = value;
        emit Approve(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        assert(from != address(0x0) && to != address(0x0) && from != to);
        assert(value > 0);
        assert(allowance[from][msg.sender] >= value);

        balanceOf[from] = SafeMath.safeSub(balanceOf[from], value);
        balanceOf[to] = SafeMath.safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = SafeMath.safeSub(allowance[from][msg.sender], value);

        emit TransferFrom(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) external override returns (bool) {
        assert(to != address(0x0));
        assert(value > 0);
        assert(msg.sender == owner);

        balanceOf[to] = SafeMath.safeAdd(balanceOf[to], value);

        return true;
    }

    function burn(address from, uint256 value) external override returns (bool) {
        assert(from != address(0x0));
        assert(value > 0);
        assert(msg.sender == owner);

        balanceOf[from] = SafeMath.safeSub(balanceOf[from], value);

        return true;
    }

}