// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

error ETHPool__NotTheOwner();
error ETHPool__NotEnoughFunds();

contract ETHPool {
    address public owner;
    mapping(address => uint256) public deposits;
    address[] public depositors;
    uint256 public totalDeposits;

    modifier isOwner() {
        if (owner != msg.sender) {
            revert ETHPool__NotTheOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// external
    ///

    function deposit() external payable {
        _deposit();
    }

    receive() external payable {
        _deposit();
    }

    fallback() external payable {
        _deposit();
    }

    function withdraw(uint256 amount) external {
        if (amount > deposits[msg.sender]) {
            revert ETHPool__NotEnoughFunds();
        }

        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");

        require(ok, "Withdrawal failed");
    }

    /// owner
    ///

    function depositRewards() external payable isOwner {
        uint256 precision = 1e18;

        for (uint256 i = 0; i < depositors.length; i++) {
            address depositor = depositors[i];
            uint256 depositorBalance = deposits[depositor];
            uint256 rewardPct = depositorBalance * precision / totalDeposits;
            deposits[depositor] += msg.value * rewardPct / precision;
        }

        totalDeposits += msg.value;
    }

    /// private
    ///

    function _deposit() private {
        depositors.push(msg.sender);
        deposits[msg.sender] += msg.value; 
        totalDeposits += msg.value;
    }
}