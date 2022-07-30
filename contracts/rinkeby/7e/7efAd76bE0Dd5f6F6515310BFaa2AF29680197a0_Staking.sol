//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface TestToken {
    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

contract Staking {
    address private testToken = 0x6c8262A10982EbA0ABA19Dd22097eabbFa3c3466;

    mapping(address => uint256) private stakedBalances;
    mapping(address => uint256) private stakedTimes;

    function depositTokens(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(
            TestToken(testToken).balanceOf(msg.sender) > amount,
            "Not enough token"
        );

        TestToken(testToken).transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        stakedTimes[msg.sender] = block.timestamp;
    }

    function withdrawTokens(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(
            stakedBalances[msg.sender] >= amount,
            "Not enough deposited token"
        );

        TestToken(testToken).transferFrom(address(this), msg.sender, amount);
        stakedBalances[msg.sender] -= amount;
    }

    function stakedBalanceOf(address account) external view returns (uint256) {
        return stakedBalances[account];
    }

    function stakedTimeOf(address account) external view returns (uint256) {
        return stakedTimes[account];
    }
}