// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error ETHPool__DepositValueMustBeAboveZero();
error ETHPool__UserHasNoBalance(address user);
error ETHPool__OnlyTeamCanDepositRewards(address depositor);

contract ETHPool {
    // Events
    event Deposit(address indexed depositor, uint256 indexed amount);

    event Withdrawal(address indexed depositor, uint256 indexed amount);

    event RewardDeposit(uint256 indexed amount);

    // Local variables
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    address public team;

    constructor() {
        team = msg.sender;
    }

    /**
     * @notice Deposits ETH into the pool in order to earn interest.
     */
    function deposit() public payable {
        uint256 amount = msg.value;

        if (amount == 0) revert ETHPool__DepositValueMustBeAboveZero();

        uint256 shares;
        if (totalSupply == 0) shares = amount;
        else shares = (amount * totalSupply) / (address(this).balance - amount);

        _mint(msg.sender, shares);

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraws ETH from the pool with interest.
     * @dev The contract is safe from Reentrancy Vulnerabilities as it updates the balances before transferring the assets.
     */
    function withdraw() public {
        if (balances[msg.sender] == 0) revert ETHPool__UserHasNoBalance(msg.sender);

        uint256 shares = balances[msg.sender];
        uint256 amount = (shares * address(this).balance) / totalSupply;

        _burn(msg.sender, shares);

        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice Deposits rewards into the pool.
     * @dev Only the team can deposit rewards.
     */
    function depositReward() public payable {
        if (msg.sender != team) revert ETHPool__OnlyTeamCanDepositRewards(msg.sender);
        if (msg.value == 0) revert ETHPool__DepositValueMustBeAboveZero();

        emit RewardDeposit(msg.value);
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal {
        totalSupply -= amount;
        balances[account] -= amount;
    }

    receive() external payable {
        depositReward();
    }
}