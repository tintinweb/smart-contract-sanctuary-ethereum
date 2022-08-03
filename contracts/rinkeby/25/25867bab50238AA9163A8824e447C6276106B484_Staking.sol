//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface TestToken {
    function owner() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

contract Staking {
    address private testToken = 0xA8a5d46531402c0930b154ada57620300d7da4C0;
    address private testTokenOwner = TestToken(testToken).owner();

    mapping(address => uint256) private stakedBalances;
    mapping(address => uint256) private stakedTimes;
    mapping(address => uint256) private rewards;

    function depositTokens(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(
            TestToken(testToken).balanceOf(msg.sender) > amount,
            "Not enough token"
        );

        TestToken(testToken).transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        stakedTimes[msg.sender] = block.timestamp;
        // TestToken(testToken).transferFrom(
        //     testTokenOwner,
        //     address(this),
        //     amount / 10
        // );
        rewards[msg.sender] += amount / 10;
    }

    function withdrawTokens(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(
            stakedBalances[msg.sender] >= amount,
            "Not enough deposited token"
        );

        TestToken(testToken).transferFrom(address(this), msg.sender, amount);
        stakedBalances[msg.sender] -= amount;
        // TestToken(testToken).transferFrom(
        //     address(this),
        //     testTokenOwner,
        //     amount / 10
        // );
        rewards[msg.sender] -= amount / 10;
    }

    function stakedBalanceOf(address account) external view returns (uint256) {
        return stakedBalances[account];
    }

    function stakedTimeOf(address account) external view returns (uint256) {
        return stakedTimes[account];
    }

    function rewardOf(address account) external view returns (uint256) {
        return rewards[account];
    }
}