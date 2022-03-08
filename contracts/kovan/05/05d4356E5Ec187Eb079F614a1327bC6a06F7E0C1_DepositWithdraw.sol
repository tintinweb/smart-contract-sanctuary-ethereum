//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DepositWithdraw {
    address payable owner;

    // user address => user balance
    mapping (address => uint256) public balances;


    event Deposited(address, uint256);
    event Withdrawn(address, uint256);

    constructor() {
        owner = payable(msg.sender);
    }

    function approvedDeposit(address _token, uint256 _amount) external {
         (bool success) = IERC20(_token).approve(address(this), _amount);
    }

    function deposit(address _token, uint256 _amount) external {
        require(_amount > 0, "Insufficient value");
        balances[msg.sender] += _amount;
        (bool success) = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Deposit unsuccessful: transferFrom");
        emit Deposited(msg.sender, _amount);
    }

    function withdraw(address _token, uint256 _amount) external {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdraw unsuccessful");
        emit Withdrawn(msg.sender, _amount);
    }

    function empty() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}