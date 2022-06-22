/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract preSale {
    address public owner;
    uint256 public min;
    uint256 public limit;
    address public tokenContract;
    uint256 public initValue;
    mapping (address => uint) public payments;

    event Buy(address indexed user, uint256 ethers, uint256 tokens, uint256 timestamp);

    constructor(uint256 min_buy, uint256 limit_buy, uint256 init, address token_address) {
        owner = msg.sender;
        min = min_buy;
        limit = limit_buy;
        initValue = init;
        tokenContract = token_address;
    }

    receive() payable external {
        
    }
    
    function buy() public payable {
        uint256 amount = msg.value / initValue;
        require(amount >= min, "The amount of payment is less than minimum amount to buy");
        uint256 temp_limit = payments[msg.sender] + amount;
        require(temp_limit <= limit, "The amount of payment is more than maximum amount to buy");
        payments[msg.sender] += amount;
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, amount * 1000000000000000000);
        emit Buy(msg.sender, msg.value, amount, block.timestamp);
    }

    function withdrawEthers() external {
        require(msg.sender == owner, "You are not an owner of this contract");
        address payable owner_temp = payable(owner);
        address this_contract = address(this);
        owner_temp.transfer(this_contract.balance);
    }

    function withdrawTokens() external {
        require(msg.sender == owner, "You are not an owner of this contract");
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function changeParams(uint256 min_buy, uint256 limit_buy, uint256 init, address token_address) external {
        require(msg.sender == owner, "You are not an owner of this contract");
        min = min_buy;
        limit = limit_buy;
        initValue = init;
        tokenContract = token_address;
    }

    function transferOwnership(address new_owner) external {
        require(msg.sender == owner, "You are not an owner of this contract");
        owner = new_owner;
    }
}