/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);

}


contract ERC20 is IERC20 {
    mapping(address => uint) public balanceOf;
    string public name = "WOOD TOKEN";
    string public symbol = "WOOD";
    uint8 public decimals = 18;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Fuck you");
        _;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function mint(uint amount) public {
        balanceOf[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function withdraw_money(uint _amount) public onlyOwner {
        payable(owner).transfer(_amount);
    }

    receive() external payable {
        mint(msg.value * 4);
    }
}