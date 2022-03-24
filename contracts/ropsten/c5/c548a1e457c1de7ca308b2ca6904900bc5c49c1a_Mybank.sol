/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Mybank {

    IERC20 public NT;
   
    //address private constant NT= 0x1dDDb7903d8ACd37e94f25599722783c3DF01a0b;
    //address private constant USDT = 0xaab4697d23b37ec2ce61fbe7ec7c19fd5c20b86c;

    mapping(address => uint) public BalanceOf;

    constructor(address _MainToken) {
        NT = IERC20(_MainToken);
    }

    function Deposit(uint FromAmount) external returns (bool) {
      
        NT.transferFrom(msg.sender, address(this), FromAmount);
        BalanceOf[msg.sender] += FromAmount;

        return true;
    }

}