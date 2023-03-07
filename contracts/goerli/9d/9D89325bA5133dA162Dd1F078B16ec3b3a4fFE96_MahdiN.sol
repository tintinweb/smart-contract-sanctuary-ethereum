/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address reciver , uint256 money) external returns (bool);
    function transferFor(address sender , address reciver , uint256 money) external returns (bool);
    function approve(address spender , uint256 money) external returns (bool);
    function allowance(address owner , address spender) external view returns (uint256);

    event Transfer(address sender , address reciver , uint256 money);
    event Approval(address owner , address reciver , uint256 money);
}

contract MahdiN is IERC20 {
    using myMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public totalSupply_;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


    constructor() {
        name = "Mahdi";
        symbol = "MAH";
        decimal = 10;
        totalSupply_ = 10000000000;
    }

    function totalSupply() external view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }

    function transfer(address reciver , uint256 money) external returns (bool){
        require(money <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(money);
        balances[reciver] = balances[reciver].sum(money);
        emit Transfer(msg.sender,reciver,money);
        return true;
    }

    function transferFor(address sender , address reciver , uint256 money) external returns (bool){
        require(money <= balances[sender]);
        require(money <= allowed[sender][reciver]);
        balances[sender] = balances[sender].sub(money);
        allowed[msg.sender][sender] = allowed[msg.sender][sender].sub(money);
        balances[reciver] = balances[reciver].sum(money);
        emit Transfer(sender,reciver,money);
        return true;
    }

    function approve(address spender , uint256 money) external returns (bool){
        allowed[msg.sender][spender] = money;
        emit Approval(msg.sender , spender , money);
        return true;
    }

    function allowance(address owner , address spender) external view returns (uint256){
        return allowed[owner][spender];
    }


}










library myMath {
    function sum(uint256 a , uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c <= a);
        return c;
    }

    function sub(uint256 a , uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }
}