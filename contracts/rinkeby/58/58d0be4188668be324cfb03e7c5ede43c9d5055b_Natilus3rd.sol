/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance (address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve (address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Natilus3rd is IERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply_;

    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowed;

    constructor () {
        name = "NATILUS";
        symbol="NATS";
        decimals = 3;
        totalSupply_=1000000000000 ; //all tokens = 1000000000
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf (address tokenOwner) public override view returns (uint256) {
        return balance[tokenOwner];
    }

    function transfer (address receiver, uint256 amount) public override returns (bool) {
        require (amount <= balance[msg.sender]);
        balance [msg.sender] = balance [msg.sender] .sub(amount);
        balance [receiver] = balance [receiver] . add (amount);
        emit Transfer (msg.sender, receiver, amount);
        return true;
    }

    function approve(address delegate, uint256 amount) public override returns (bool) {
        allowed[msg.sender][delegate]=amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed [owner][delegate];
    }


    function transferFrom ( address owner, address buyer, uint256 amount) public override returns (bool) {
        require (amount <= balance [owner]);
        require (amount <= allowed [owner][msg.sender] );

        balance [owner] = balance [owner].sub(amount);
        allowed [owner] [msg.sender]=allowed[owner][msg.sender].sub(amount);
        balance [buyer] = balance [buyer].add(amount);
        emit Transfer (owner, buyer, amount);
        return true;
    }


}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert (b <= a);
        return a - b;
    }



    function add (uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert (c >= a);
        return c;
    }
}