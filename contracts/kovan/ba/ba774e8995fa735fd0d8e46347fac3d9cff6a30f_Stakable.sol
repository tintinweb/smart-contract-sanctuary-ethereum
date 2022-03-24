/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Stakable {
    rShayanToken public rshayanToken;
    ShayanToken public shayanToken;

    string public name = "Staking";
    address public owner;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(address _shayanToken, address _rshayanToken) {
        shayanToken = ShayanToken(_shayanToken);
        rshayanToken = rShayanToken(_rshayanToken);
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {

        require(_amount > 0, "amount cannot be 0");


        shayanToken.transferFrom(msg.sender, address(this), _amount);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;

    }

    function unstakeTokens() public {

        uint balance =stakingBalance[msg.sender];

        require(balance > 0, "staking balance cannot be 0");

        shayanToken.transfer(msg.sender, balance);

        stakingBalance[msg.sender] = 0;
      
        isStaking[msg.sender] = false;

    }

    function issueTokens() public {

        require(msg.sender == owner, "caller must be the owner");

        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                rshayanToken.transfer(recipient, balance);
            }
        }
    }

}

interface ShayanToken {
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

interface rShayanToken {
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