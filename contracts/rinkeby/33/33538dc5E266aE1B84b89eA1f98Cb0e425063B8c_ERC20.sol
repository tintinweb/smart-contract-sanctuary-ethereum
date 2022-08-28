/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


interface IERC20 {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function transferFrom(address from, address to, uint amount) external returns (bool);

    event Transfer(address from, address to, uint amount);

}

contract ERC20 is IERC20 {

    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    string public name = "NTD";
    string public symbol = "NTD";
    uint8 public decimals;

    constructor() {
        mint();
    }

    function mint() internal {
        balanceOf[msg.sender] += 100;
    }

    function transfer(address to, uint amount) external returns  (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

}