/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
/**
 * This faucet is used for Deed Token holders.
 * You can claim a variable amount of Deed Tokens after each year.
 * Your rewards depend on the amount of Deed you own compared to the total supply.
 *
 * @deedprotocol
 * deedapp.io
 *
 * A decentralized world where properties are owned and transferred via the blockchain.
 * 
 */
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract DeedRewardFaucet {
    address payable owner;
    IERC20 public token = IERC20(0x0000000000000000000000000000000000000000);
    uint256 public lockTime = 365 days;
    event Deposit(address indexed from, uint256 indexed amount);
    mapping(address => uint256) nextAccessTime;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function claimReward() public {
        uint256 withdrawalAmount;
        require(
            msg.sender != address(0),
            "Request must not originate from a zero address."
        );
        require(
            token.balanceOf(address(this)) > 0,
            "No reward is available as of now."
        );
        withdrawalAmount = token.balanceOf(address(msg.sender)) * token.balanceOf(address(this)) / token.totalSupply();
        require(
            withdrawalAmount > 0,
            "Your claimable withdrawl amount needs to be higher than 0."
        );
        require(
            block.timestamp >= nextAccessTime[msg.sender],
            "Insufficient time has passed since your last withdrawal."
        );
        require(
            token.balanceOf(address(this)) >= withdrawalAmount,
            "Not enough reward is available for this withdrawl."
        );
        nextAccessTime[msg.sender] = block.timestamp + lockTime;

        token.transfer(msg.sender, withdrawalAmount);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getRewardsContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getSenderBalance() external view returns (uint256) {
        return token.balanceOf(address(msg.sender));
    }

    function getTokenSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    function setTokenAddress(address newTokenAddress) public onlyOwner {
        token = IERC20(newTokenAddress);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }
}