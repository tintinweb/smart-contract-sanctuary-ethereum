/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

contract ClawMachine {

    address public owner;

    IERC20 public immutable token;

    mapping(address => uint) public balanceOf;
    mapping(uint => uint) public costPerPlay;
    
    event DepositERC20(address indexed sender, uint amount);
    event WithdrawalERC20(address indexed sender, address indexed receiver, uint amount);
    event Play(uint indexed machineID, uint playTimes);

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    constructor(address _token) {
        token = IERC20(_token);
    }
    // Set cost per play of a machine
    function setCostPerPlay(uint machineID, uint _costPerPlay) onlyOwner external{
        costPerPlay[machineID] = _costPerPlay;
    }

    // Deposit ERC20 Token
    function depositERC20(uint amount) external {
        require(amount >= 10*10**6, "The least deposit amount  is 10U");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Allowance not enough");
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Balance not enough");
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] += amount;
        emit DepositERC20(msg.sender, amount);
    }

    // Withdraw ERC20
    function withdrawERC20(uint256 amount, address receiver) onlyOwner external {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient ERC20 balance");
        IERC20(token).transfer(msg.sender, amount);
          
        emit WithdrawalERC20(msg.sender,  receiver, amount);
    }

    // 
    function play(uint machineID, uint playTimes) external {
        uint amount  = costPerPlay[machineID] * playTimes; 
        require( balanceOf[msg.sender] >= amount, "Deposit not enough");
        
        balanceOf[msg.sender] -= amount;

        emit Play(machineID, playTimes);
    }
    function totalBlanceOf() view onlyOwner external returns(uint){
        return IERC20(token).balanceOf(address(this));
    }
}