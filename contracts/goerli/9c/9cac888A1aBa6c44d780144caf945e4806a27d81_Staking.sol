pragma solidity ^0.8.9;

interface TestToken {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}
contract Staking {
    mapping(address => uint256) stakedBalances;
    mapping(address => uint256) stakedTimes;
    address testTokenAddress = 0xafa41aFe3a04734c93d7E8dcFE6Bc2Ce34cbcDEA;

    function depositTokens(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(TestToken(testTokenAddress).balanceOf(msg.sender) > amount, "Not enough token");

        TestToken(testTokenAddress).transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        stakedTimes[msg.sender] = block.timestamp;
    }

    function withdrawTokens(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(
            stakedBalances[msg.sender] > amount,
            "Not enough deposited token"
        );

        TestToken(testTokenAddress).transferFrom(address(this), msg.sender, amount);
        stakedBalances[msg.sender] -= amount;
    }

    function stakedBalanceOf(address account) external view returns (uint256) {
        return stakedBalances[account];
    }

    function stakedTimeOf(address account) external view returns (uint256) {
        return stakedTimes[account];
    }
}