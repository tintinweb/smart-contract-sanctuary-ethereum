/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract ERC20 is IERC20 {
    uint256 _totalSupply;
    mapping(address => uint256) _balance;

    constructor() {
        _totalSupply = 100000;
        _balance[msg.sender] = 100000;
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balance[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        uint256 myBalance =  _balance[msg.sender];
        require (myBalance >= amount, "No money to transfer");
        require (to != address(0x0), "Transfer to address 0");

        _balance[msg.sender] -= amount;
        _balance[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

}